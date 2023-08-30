import argparse
import asyncio
import json
import subprocess
from pathlib import Path

import jupyter_client
from jupyter_client.manager import start_new_async_kernel


def get_task_for_name(client, name):
    match name:
        case "stdin":
            coroutine = client.get_stdin_msg()
        case "control":
            coroutine = client.get_control_msg()
        case "shell":
            coroutine = client.get_shell_msg()
        case "iopub":
            coroutine = client.get_iopub_msg()
        case x:
            raise Exception("Unknown msg type " + x)

    return asyncio.create_task(coroutine, name=name)


async def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('file', action='store', help='The Typst file to compile')
    parser.add_argument('--typst-command', default='typst', action='store', help='The Typst executable to use')

    args = parser.parse_args()
    file_path = Path(args.file)

    output = subprocess.check_output([args.typst_command, 'query', file_path, 'selector(<typst-notebook>).or(<typst-notebook-cell>)'])
    labels = json.loads(output)
    print(labels)
    output_directory = file_path.parent / '.typst-notebook'
    output_directory.mkdir(exist_ok=True)

    manager = jupyter_client.AsyncMultiKernelManager()
    notebooks = {}

    for label in labels:
        match label:
            case {'label': "<typst-notebook>", 'value': notebook}:
                if notebook['id'] in manager.list_kernel_ids():
                    raise Exception(f"Notebook with id {notebook['id']} already exists")
                await manager.start_kernel(kernel_name=notebook['kernel'], kernel_id=notebook['id'])
                notebooks[label['value']['id']] = []
            case {'label': "<typst-notebook-cell>", 'value': cell}:
                client = manager.get_kernel(cell['notebook']).client()
                cell_info = {
                    'code': cell['code'],
                    'display-data': []
                }
                notebooks[cell['notebook']].append(cell_info)

                print("Running", cell['code'])
                client.execute(cell['code'])
                status = 'busy'
                while status != 'idle':
                    msg = await client.get_iopub_msg()
                    match msg['msg_type']:
                        case 'status':
                            status = msg['content']['execution_state']
                        case 'display_data' | 'execute_result':
                            cell_info['display-data'].append(msg['content']['data'])
                        case 'execute_input':
                            pass
                        case x:
                            print(f"Unhandled {x}")

    await manager.shutdown_all()
    with open(output_directory / "output.json", 'w+') as f:
        json.dump(notebooks, f)

    subprocess.run([args.typst_command, 'compile', file_path])


    """
    stdin_task = get_task_for_name(client, "stdin")
    control_task = get_task_for_name(client, "control")
    shell_task = get_task_for_name(client, "shell")
    iopub_task = get_task_for_name(client, "iopub")

    tasks = {stdin_task, control_task, shell_task, iopub_task}
    while True:
        done, tasks = await asyncio.wait(tasks, return_when=asyncio.FIRST_COMPLETED)

        for task in done:
            msg = await task
            tasks.add(get_task_for_name(client, task.get_name()))
            if task.get_name() == "iopub" and msg['header']['msg_type'] == "stream":
                print(msg['content']['text'])
            else:
                print(task.get_name(), msg)
    """


if __name__ == '__main__':
    asyncio.run(main())
