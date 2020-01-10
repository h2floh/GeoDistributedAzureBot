using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using GeoBot.Helpers;
using Microsoft.AspNetCore.Mvc;

namespace GeoBot.Controllers
{
    [ApiController]
    public class DirectlineController : ControllerBase
    {
        private readonly Directline directline;
        public DirectlineController(Directline directline)
        {
            this.directline = directline;
        }

        [Route("directline/token")]
        [HttpGet]
        public async Task<Token> GetAsync()
        {
            Token token = new Token
            {
                token = await directline.GetDirectlineToken()
            };

            return token;
        }
    }
}