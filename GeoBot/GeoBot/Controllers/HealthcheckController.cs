using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;

namespace GeoBot.Controllers
{
    // This ASP Controller is created to handle healthcheck requests from TrafficManager.
    [Route("healthcheck")]
    [ApiController]
    public class HealthcheckController : ControllerBase
    {
        private readonly Healthcheck healthcheck;

        public HealthcheckController(Healthcheck healthcheck)
        {
            this.healthcheck = healthcheck;
        }

        [HttpGet]
        public async Task GetAsync()
        {
            // Execute Healthcheck
            await healthcheck.CheckHealthAsync(Response);
        }
    }
}