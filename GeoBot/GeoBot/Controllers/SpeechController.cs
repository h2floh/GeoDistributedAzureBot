using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using GeoBot.Helpers;
using Microsoft.AspNetCore.Mvc;

namespace GeoBot.Controllers
{
    // This ASP Controller is created to handle healthcheck requests from TrafficManager.
    [ApiController]
    public class SpeechController : ControllerBase
    {
        private readonly Speech speech;

        public SpeechController(Speech speech)
        {
            this.speech = speech;
        }

        [Route("speech/token")]
        [HttpGet]
        public async Task<Token> GetTokenAsync()
        {
            Token token = new Token
            {
                token = await speech.GetSpeechToken()
            };

            return token;
        }

        [Route("speech/region")]
        [HttpGet]
        public async Task<Token> GetRegionAsync()
        {
            Token token = new Token
            {
                token = await speech.GetSpeechToken()
            };

            return token;
        }
    }
}