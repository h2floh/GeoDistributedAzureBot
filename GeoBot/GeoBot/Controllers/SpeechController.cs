using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
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
        public async Task<SpeechToken> GetTokenAsync()
        {
            SpeechToken speechToken = new SpeechToken
            {
                token = await speech.GetSpeechToken(),
                region = speech.GetSpeechRegion()
            };

            return speechToken;
        }
    }

    public class SpeechToken
    {
        public string token { get; set; }
        public string region { get; set; }
    }

}