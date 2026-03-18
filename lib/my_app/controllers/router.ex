defmodule MyApp.Router do
  use Ignite.Router

  # Look how easy it is to read! This is called a Domain Specific Language (DSL).
  get("/", to: MyApp.WelcomeController, action: :index)
  get("/hello", to: MyApp.WelcomeController, action: :hello)
  resources "/users", MyApp.UserController

  # Validation Routes
  get("/test-render", to: MyApp.WelcomeController, action: :test_render)
  get("/test-error", to: MyApp.WelcomeController, action: :test_error)

  # Upload Routes
  get("/upload", to: MyApp.UploadController, action: :upload_form)
  post("/upload", to: MyApp.UploadController, action: :upload)
  get("/upload-demo", to: MyApp.WelcomeController, action: :upload_demo)

  scope "/api" do
    get("/status", to: MyApp.ApiController, action: :status)
    post("/echo", to: MyApp.ApiController, action: :echo)
  end

  live("/hooks-demo", MyApp.HooksDemoLive)
  live("/shared-counter", MyApp.SharedCounterLive)
  live("/components", MyApp.ComponentsDemoLive)
  live("/streams", MyApp.StreamDemoLive)
  live("/presence", MyApp.PresenceDemoLive)

  finalize_routes()
end
