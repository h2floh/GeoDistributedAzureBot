using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;

namespace GeoBot.Controllers
{
    [Route("getregion")]
    [ApiController]
    public class GetRegionController : ControllerBase
    {
        private readonly Healthcheck healthcheck;
        public GetRegionController(Healthcheck healthcheck)
        {
            this.healthcheck = healthcheck;
        }

        [HttpGet]
        public string GetAsync()
        {
            return healthcheck.GetSpeechRegion();
        }
    }
}