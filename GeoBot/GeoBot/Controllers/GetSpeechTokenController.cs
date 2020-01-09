using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;

namespace GeoBot.Controllers
{
    // This ASP Controller is created to handle healthcheck requests from TrafficManager.
    [Route("getspeechtoken")]
    [ApiController]
    public class GetSpeechTokenController : ControllerBase
    {
        private readonly Healthcheck healthcheck;

        public GetSpeechTokenController(Healthcheck healthcheck)
        {
            this.healthcheck = healthcheck;
        }

        [HttpGet]
        public async Task<string> GetAsync()
        {
            return await healthcheck.GetSpeechToken();
        }
    }
}