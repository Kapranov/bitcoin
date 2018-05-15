use Mix.Config

if Mix.env == :dev do
  config :mix_test_watch,
    clear: true
end

# Notification Types
config :ex_unit_notifier, notifier: ExUnitNotifier.Notifiers.NotifySend
# config :ex_unit_notifier, notifier: ExUnitNotifier.Notifiers.TerminalNotifier
# config :ex_unit_notifier, notifier: ExUnitNotifier.Notifiers.TerminalTitle

# import_config "#{Mix.env}.exs"
