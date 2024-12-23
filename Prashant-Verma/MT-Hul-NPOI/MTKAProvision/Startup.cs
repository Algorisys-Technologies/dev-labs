using Microsoft.Owin;
using Owin;

[assembly: OwinStartupAttribute(typeof(MTKAProvision.Startup))]
namespace MTKAProvision
{
    public partial class Startup
    {
        public void Configuration(IAppBuilder app)
        {
            ConfigureAuth(app);
           
        }
    }
}
