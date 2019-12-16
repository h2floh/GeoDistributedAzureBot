// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.
//
// Generated with Bot Builder V4 SDK Template for Visual Studio CoreBot v4.6.2

using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Bot.Builder;
using Microsoft.Bot.Builder.Dialogs;
using Microsoft.Bot.Schema;
using Microsoft.Extensions.Logging;
using Microsoft.Recognizers.Text.DataTypes.TimexExpression;

using GeoBot;
using GeoBot.CognitiveModels;
using System.Configuration;
using Microsoft.Extensions.Configuration;
using Newtonsoft.Json;

namespace GeoBot.Dialogs
{
    public class MainDialog : ComponentDialog
    {
        private readonly AddressRecognizer _luisRecognizer;
        protected readonly ILogger Logger;
        protected readonly IConfiguration configuration;

        // Dependency injection uses this constructor to instantiate MainDialog
        public MainDialog(AddressRecognizer luisRecognizer, ILogger<MainDialog> logger, IConfiguration config)
            : base(nameof(MainDialog))
        {
            _luisRecognizer = luisRecognizer;
            Logger = logger;
            configuration = config;

            AddDialog(new TextPrompt(nameof(TextPrompt)));
            AddDialog(new WaterfallDialog(nameof(WaterfallDialog), new WaterfallStep[]
            {
                IntroStepAsync,
                ActStepAsync
            }));

            // The initial child Dialog to run.
            InitialDialogId = nameof(WaterfallDialog);
        }

        private async Task<DialogTurnResult> IntroStepAsync(WaterfallStepContext stepContext, CancellationToken cancellationToken)
        {
            if (!_luisRecognizer.IsConfigured)
            {
                var keyVaultName = configuration["KeyVaultName"];
                await stepContext.Context.SendActivityAsync(
                    MessageFactory.Text($"NOTE: LUIS is not configured. To enable all capabilities, add 'LuisAppId' as a secret to your keyvault named '{keyVaultName}'", inputHint: InputHints.IgnoringInput), cancellationToken);

                return await stepContext.NextAsync(null, cancellationToken);
            }

            // Use the text provided in FinalStepAsync or the default if it is the first time.
            var messageText = stepContext.Options?.ToString() ?? "What can I help you with today?\nSay something like \"Go to adress 8178 161st avenue northeast, redmond, washington\"";
            var promptMessage = MessageFactory.Text(messageText, messageText, InputHints.ExpectingInput);
            return await stepContext.PromptAsync(nameof(TextPrompt), new PromptOptions { Prompt = promptMessage }, cancellationToken);
        }

        private async Task<DialogTurnResult> ActStepAsync(WaterfallStepContext stepContext, CancellationToken cancellationToken)
        {
            if (!_luisRecognizer.IsConfigured)
            {
                // LUIS is not configured, we just run the TextPrompt again
                var promptMessage = MessageFactory.Text("Something went completely wrong with the message flow!");
                return await stepContext.PromptAsync(nameof(TextPrompt), new PromptOptions { Prompt = promptMessage }, cancellationToken);
            }

            // Call LUIS and gather any potential booking details. (Note the TurnContext has the response to the prompt.)
            var luisResult = await _luisRecognizer.RecognizeAsync<AddressFinder>(stepContext.Context, cancellationToken);
            switch (luisResult.TopIntent().intent)
            {
                case AddressFinder.Intent.POI_GetAddress:

                    var textResult = JsonConvert.SerializeObject(luisResult);
                    var getAddressText = $"GetAddress Result:\n{textResult}";
                    var getAddressMessage = MessageFactory.Text(getAddressText, getAddressText, InputHints.IgnoringInput);
                    await stepContext.Context.SendActivityAsync(getAddressMessage, cancellationToken);
                    break;

                default:
                    // Catch all for unhandled intents
                    var didntUnderstandMessageText = $"Sorry, I didn't get that. Please try asking in a different way (intent was {luisResult.TopIntent().intent})";
                    var didntUnderstandMessage = MessageFactory.Text(didntUnderstandMessageText, didntUnderstandMessageText, InputHints.IgnoringInput);
                    await stepContext.Context.SendActivityAsync(didntUnderstandMessage, cancellationToken);
                    break;
            }

            return await stepContext.NextAsync(null, cancellationToken);
        }
    }
}
