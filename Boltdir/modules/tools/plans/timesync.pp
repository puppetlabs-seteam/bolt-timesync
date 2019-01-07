plan tools::timesync(
  TargetSpec $nodes,
) {
  run_task('tools::timesync', $nodes, restart => false)
  run_task('service::windows', $nodes, name => 'W32Time', action => 'restart')
}
