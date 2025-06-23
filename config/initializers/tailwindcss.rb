Tailwindcss::Rails.configure do |config|
  config.config_path = Rails.root.join("config", "tailwind.config.js")
  config.content = [
    Rails.root.join("app/views/**/*.{html,html.erb,erb,slim}"),
    Rails.root.join("app/helpers/**/*.rb"),
    Rails.root.join("app/javascript/**/*.js"),
    Rails.root.join("public/*.html"),
  ]
end
