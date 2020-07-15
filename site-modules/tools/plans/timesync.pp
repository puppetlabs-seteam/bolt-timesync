plan tools::timesync(
  TargetSpec $targets,
) {
  run_task('tools::timesync', $targets, restart => false)
  run_task('service::windows', $targets, name => 'W32Time', action => 'restart')
}
