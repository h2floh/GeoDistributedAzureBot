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
        protected readonly string region;
        protected readonly string AcutualLUISStepDialogId;

        // Dependency injection uses this constructor to instantiate MainDialog
        public MainDialog(AddressRecognizer luisRecognizer, ILogger<MainDialog> logger, IConfiguration config)
            : base(nameof(MainDialog))
        {
            _luisRecognizer = luisRecognizer;
            Logger = logger;
            configuration = config;
            region = configuration["region"];

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
                    MessageFactory.Text($"NOTE: LUIS is not configured. To enable all capabilities, add 'LuisAppId' as a secret to your keyvault named '{keyVaultName}'. Replied from Azure region {region}.", inputHint: InputHints.IgnoringInput), cancellationToken);

                return await stepContext.NextAsync(null, cancellationToken);
            }

            // Use the text provided in FinalStepAsync or the default if it is the first time.      
            var messageText = stepContext.Options?.ToString() ?? $"Hi! I am located in Azure region {region}. What can I help you with today?\nSay something like \"Go to adress 8178 161st avenue northeast, redmond, washington\"";
            var promptMessage = MessageFactory.Text(messageText, messageText, InputHints.ExpectingInput);
            return await stepContext.PromptAsync(nameof(TextPrompt), new PromptOptions { Prompt = promptMessage }, cancellationToken);
        }

        private async Task<DialogTurnResult> ActStepAsync(WaterfallStepContext stepContext, CancellationToken cancellationToken)
        {
            if (!_luisRecognizer.IsConfigured)
            {
                // LUIS is not configured, we just run the TextPrompt again
                var errorMessage = MessageFactory.Text($"Something went completely wrong with the message flow! Replied from Azure region {region}.");
                return await stepContext.PromptAsync(nameof(TextPrompt), new PromptOptions { Prompt = errorMessage }, cancellationToken);
            }

            // Call LUIS and gather any potential booking details. (Note the TurnContext has the response to the prompt.)
            var luisResult = await _luisRecognizer.RecognizeAsync<AddressFinder>(stepContext.Context, cancellationToken);
            switch (luisResult.TopIntent().intent)
            {
                case AddressFinder.Intent.Utilities_Cancel:

                    // Cancel LUIS test
                    var cancelText = $"OK starting over!\n\nReplied from Azure region {region}.".Replace("\n", "\n\n");
                    var cancelMessage = MessageFactory.Text(cancelText, cancelText, InputHints.IgnoringInput);
                    await stepContext.Context.SendActivityAsync(cancelMessage, cancellationToken);
                    return await stepContext.EndDialogAsync(null, cancellationToken);

                default:
                    // Catch all for unhandled intents
                    var textResult = JsonConvert.SerializeObject(luisResult, Formatting.Indented);
                    var getAddressText = $"I understood that your intent was {luisResult.TopIntent().intent}:\nDetails:\n{textResult}\n\nReplied from Azure region {region}.".Replace("\n", "\n\n"); 
                    var getAddressMessage = MessageFactory.Text(getAddressText, getAddressText, InputHints.IgnoringInput);
                    await stepContext.Context.SendActivityAsync(getAddressMessage, cancellationToken);
                    break;
            }

            return await stepContext.ReplaceDialogAsync(InitialDialogId, null, cancellationToken);
        }
    }
}
