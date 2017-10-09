#!/usr/bin/python
import getpass
import subprocess
import time

from dialog import Dialog

def raise_error(message):
    raise Exception(message)

def run_cmd(cmd, ignore_errors=False):
    cmd_run = subprocess.Popen(cmd.split(), stdout=subprocess.PIPE,
                               stderr=subprocess.PIPE)
    output, error = cmd_run.communicate()
    if cmd_run.returncode != 0 and not ignore_errors:
        raise_error("\nSomethin wrong, output is:\n{}error "
                        "is:\n{}".format(output, error))
    return(output, error)

def run_cmds(cmds, ignore_errors=False):
    outputs = []
    errors = []
    for cmd in cmds:
        output, error = run_cmd(cmd, ignore_errors)
        outputs.append(output)
        errors.append(error)
    return(outputs, errors)

def main():
    if getpass.getuser() != "hadoop":
        raise_error("Please start from user hadoop")
    slaves_file = "/opt/hadoop/etc/hadoop/slaves"
    nodes_excluded_file = "/opt/hadoop/etc/hadoop/nodes.exlude"
    with open(slaves_file) as f:
        slaves_lines = f.read().splitlines()
    f.close()
    with open(nodes_excluded_file) as f:
        nodes_excluded_lines = f.read().splitlines()
    f.close()

    choices_list = []
    for node in slaves_lines:
        if len(node) > 5:
            if node in nodes_excluded_lines:
                choices_list.append((node, '', True))
            else:
                choices_list.append((node, '', False))

    dialog = Dialog(dialog='dialog')
    (code, hosts) = dialog.checklist(
        text="Decommiss nodes managment",
        height=35, width=64, list_height=20,
        title="Decommiss nodes managment",
        backtitle="Decommiss nodes managment",
        choices=choices_list)

    if hosts != nodes_excluded_lines and code == dialog.OK:
        dialog.infobox("Write new nodes.exlude file")
        f = open(nodes_excluded_file, 'w')
        for host in hosts:
            f.write("{}\n".format(host))
        f.close()
        hosts.sort()
        nodes_excluded_lines.sort()
        dialog.infobox("Refresh nodes")
        run_cmds(
            ["/opt/hadoop/bin/hdfs dfsadmin -refreshNodes",
             "/opt/hadoop/bin/yarn rmadmin -refreshNodes"])
        online_hosts = list(set(nodes_excluded_lines) - set(hosts))
        if len(online_hosts) > 0:
            dialog.infobox("Starting datanode and nodemanager on the {}".format(
                " ".join(online_hosts)
            ))
        for host in online_hosts:
            hadoop_sbin_path = "/opt/hadoop/sbin"
            run_cmds(
                ["/usr/bin/ssh {} {}/hadoop-daemon.sh start datanode".format(
                     host, hadoop_sbin_path
                ),
                 "/usr/bin/ssh {} {}/yarn-daemon.sh start nodemanager".format(
                     host, hadoop_sbin_path
                 )], ignore_errors=True)
        timeout = 30*60
        duration = 0
        progress = 0
        decommissioning_done = False
        time.sleep(30)
        dialog.gauge_start("Decommissioning in progress")
        while not decommissioning_done:
            output, error = run_cmd(
                "/opt/hadoop/bin/hdfs dfsadmin -report -decommissioning"
                )
            if ("Decommission in progress" in output or
                "Decommission in progress" in error):
                progress += 1
                dialog.gauge_update(progress)
                time.sleep(30)
                duration += 30
            else:
                decommissioning_done = True
            if duration > timeout:
                raise_error("Decommissioning timeout")
        dialog.gauge_update(100)
        dialog.gauge_stop()


if __name__ == '__main__':
    main()

