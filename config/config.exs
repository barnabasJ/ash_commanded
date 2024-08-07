import Config

config :ash, :use_all_identities_in_manage_relationship?, false

if Mix.env() == :test do
  config :ash_commanded, ash_domains: [CommandedTest.A.Domain]
end
