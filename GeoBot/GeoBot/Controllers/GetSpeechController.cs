using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;

namespace GeoBot.Controllers
{
    [Route("getspeech")]
    [ApiController]
    public class GetSpeechController : ControllerBase
    {
        private readonly Healthcheck healthcheck;
        public GetSpeechController(Healthcheck healthcheck)
        {
            this.healthcheck = healthcheck;
        }

        [HttpGet]
        public async Task<SpeechServiceValue> GetAsync()
        {

            SpeechServiceValue speechServiceValue = new SpeechServiceValue
            {
                Region = healthcheck.GetSpeechRegion(),
                Token = await healthcheck.GetSpeechToken()
            };
            return speechServiceValue;
        }

    }

    public class SpeechServiceValue
    {
        public string Token;
        public string Region;
    }
}