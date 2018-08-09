using System;
using System.Linq;
using Microsoft.AspNetCore;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;

namespace TestANCM
{
    public class Program
    {
        public static void Main(string[] args) 
            => CreateWebHostBuilder(args).Build().Run();

        public static IWebHostBuilder CreateWebHostBuilder(string[] args) 
            => WebHost.CreateDefaultBuilder(args).UseStartup<Startup>();
    }

    class Startup
    {
        public void Configure(IApplicationBuilder app, IHostingEnvironment env)
        {
            app.Run(async (context) =>
            {
                string nl = Environment.NewLine;
                await context.Response.WriteAsync(
                    "HttpContext.User.Identity.Name = " + context.User.Identity.Name + nl +
                    "Header[MS-ASPNETCORE-USER]     = " + context.Request.Headers["MS-ASPNETCORE-USER"] + nl +
                    "ASPNETCORE_IIS_HTTPAUTH        = " + Environment.GetEnvironmentVariable("ASPNETCORE_IIS_HTTPAUTH"));

                await context.Response.WriteAsync(nl + nl + "Request headers:" + nl + nl);

                foreach (var pair in context.Request.Headers.OrderBy(_ => _.Key, StringComparer.OrdinalIgnoreCase))
                {
                    await context.Response.WriteAsync(pair.Key + ": " + pair.Value + Environment.NewLine);
                }
            });
        }
    }
}
