# Debug Track: Deployment Hypotheses and Live Troubleshooting

## Part 1: Foreground-SSH vs Binding Hypotheses (Core Requirement)
During the design of the deployment pipeline, I had to decide how to execute the binary on the target machine. Here are the hypotheses tested regarding process execution and binding:

**Hypothesis 1: The Foreground-SSH Block**
* *Action:* Deploying the binary by running `ssh laborant@target './binary-app'`.
* *Result:* The Jenkins pipeline hangs indefinitely. 
* *Why:* SSH binds standard input/output to the foreground process. Jenkins waits for the SSH command to return an exit code. Because the application is a continuously running web server, the SSH session never terminates. The pipeline is permanently blocked and will eventually time out.

**Hypothesis 2: The Background/Nohup Attempt**
* *Action:* Attempting to cheat the foreground block using `ssh laborant@target 'nohup ./binary-app &'`.
* *Result:* The pipeline might finish, but the deployment is brittle and non-idempotent.
* *Why:* While it detaches the process from the SSH session, there is no state management. If I run the pipeline a second time, it crashes with a "port 4444 already in use" error because the old process is still bound to the port. Furthermore, if the server reboots, the application stays dead.

**Hypothesis 3: The Systemd Solution (Implemented)**
* *Action:* Copying `myapp.service` to `/etc/systemd/system/` and issuing `systemctl restart myapp.service` via SSH.
* *Result:* The pipeline succeeds, proceeds to the health check, and the deployment is highly resilient.
* *Why:* By handing the binary over to the system's init daemon, the SSH command simply sends a signal to systemd and immediately returns an exit code of `0`. Jenkins is freed to move to the next stage. Systemd natively binds the process to the background, manages the port safely during restarts, and provides `Restart=on-failure` resiliency.

---

## Part 2: Live Pipeline Debugging Log
Beyond the architectural hypotheses, here is the log of real-world errors encountered in the iximiuz lab environment and how they were resolved.

**Error 1: Exit Code 127 (`go: not found`)**
* *Symptom:* The Jenkins build stage failed immediately when executing `go build -o binary-app main.go`.
* *Diagnosis:* The Jenkins master node did not have the Go compiler installed natively. 
* *Resolution:* Instead of refactoring the pipeline to rely on a heavy Docker container, I configured Jenkins to handle it natively. I installed the **Go Plugin** in Jenkins, configured a Global Tool named `1.24.1`, and injected a `tools { go '1.24.1' }` block into the `Jenkinsfile`.

**Error 2: `java.lang.NoSuchMethodError: No such DSL method 'sshagent' found`**
* *Symptom:* The pipeline crashed at the `Deploy to Target` stage because Jenkins didn't recognize the `sshagent` wrapper.
* *Diagnosis:* The specific Jenkins instance provisioned by the lab's seed job did not include the SSH Agent plugin out-of-the-box.
* *Resolution:* Navigated to the Jenkins Plugin Manager, searched the "Available Plugins" tab, installed the **SSH Agent** plugin, and restarted the build. The pipeline successfully decrypted the `ed25519` key and authenticated as the `laborant` user.

**Error 3: SSH Authorization Denied**
* *Symptom:* While manually testing the lab environment, attempting to append the public key to `~/.ssh/authorized_keys` resulted in `permission denied`.
* *Diagnosis:* The lab's environment was highly curated; the target machine already pre-authorized the pre-generated `ed25519` key.
* *Resolution:* Skipped the authorization step, directly copied the existing private key from the target machine, and saved it in Jenkins Credentials as `target-ssh-key` without a passphrase.