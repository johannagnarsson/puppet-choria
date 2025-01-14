# Runs a specific Puppet Task
#
# When running in the background and in batches this does not imply
# that the task is completed between batches it means the task will
# be requested in these batches regardless of the state of the other nodes
#
# When run in the foregroun it will wait up to 60 seconds for nodes to
# complete a task, if by then they did not complete the task it will move
# onto the next batch
#
# @param nodes The nodes to run the task on
# @param task The name of the task to run
# @param inputs The inputs to pass to the task
# @param background When true does not wait for the task to complete
# @param silent Surpress logging of individual node results
# @param batch_size When not 0, run the task on nodes in batches
# @params batch_sleep_time How long to sleep between batches
# @param tasks_environment The environment to find tasks
plan choria::tasks::run(
  Choria::Nodes $nodes,
  String $task,
  Hash $inputs,
  Boolean $background = false,
  Boolean $silent = false,
  Integer $batch_size = 0,
  Integer $batch_sleep_time = 2,
  Optional[String[1]] $run_as = undef,
  String[1] $tasks_environment = "production",
) {
  $metadata = choria::tasks::metadata($task)

  choria::tasks::validate_input($inputs, $metadata)

  choria::run_playbook("choria::tasks::download_files",
    "nodes"       => $nodes,
    "task"        => $task,
    "files"       => $metadata["files"],
    "environment" => $tasks_environment,
  )

  if $background {
    $action = "bolt_tasks.run_no_wait"
  } else {
    $action = "bolt_tasks.run_and_wait"
  }

  info("Running task '${task}' on ${nodes.size} nodes")

  if $run_as {
    $run_as_property = { "run_as" => $run_as }
  } else {
    $run_as_property = {}
  }

  choria::task(
    "nodes"            => $nodes,
    "action"           => $action,
    "batch_size"       => $batch_size,
    "batch_sleep_time" => $batch_sleep_time,
    "silent"           => $silent,
    "properties"       => {
      "task"           => $task,
      "files"          => $metadata["files"].stdlib::to_json,
      "input"          => $inputs.stdlib::to_json
    } + $run_as_property
  )
}
