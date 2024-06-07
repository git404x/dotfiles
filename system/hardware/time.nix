{ systemConfig, ... }:

{
  # Set your time zone.
  time.timeZone = systemConfig.timezone;
  time.hardwareClockInLocalTime = true;
}
