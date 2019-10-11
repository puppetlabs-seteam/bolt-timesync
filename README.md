# Demonstrating the Puppet Bolt automation journey with NTP

Perform these preparatory steps first for this demo:
* Spin up a Windows VM and ensure you can reach it via WinRM (run `winrm quickconfig` if needed)
* Ensure Guest time synchronization (through VirtualBox or VMware Fusion) is disabled for this VM.
* Change the Win32Time settings to sync to a non-existing server:<br/>
  `w32tm /config /update /manualpeerlist:"i.dont.exist"`<br/>
  (You will need to re-run this command before a new demo to get back to the initial demo state)
* Install the Puppet Agent (for speed during the demo), but change the puppet agent configuration to point to a non-existing master and stop the puppet and pxp-agent services.<br/>
(You will need to redo this before a new demo to get back to the initial demo state)
* Clone this repo into a demo folder:<br/>
  `git clone https://github.com/kreeuwijk/bolt-timesync`
* Update the `inventory.yaml` file:
    * Update the IP address to the IP of your Windows VM
    * Update the username & password for the WinRM credentials you're using

<br/>**To enable the later part of the demo where you integrate with PE, follow these steps**
* Update the `bolt.yaml` file:
    * Update the service-url to point to your PE master
    * Ensure you have a copy of the PE Master CA certificate and specify the path to where you have it stored
    * Ensure you have a copy of the PE Master RBAC token and specify the path to where you have it stored. If you don't have one yet, run `puppet access login` on the master to generate one.
* Ensure you have a `tools` module on your Gitlab instance used by PE. If you don't have a `tools` module, create an new one and add it to your control-repo's Puppetfile. Ensure the module has a `tasks` and a `plans` folder.
* Copy the tasks in `site-modules/tools/tasks` to the `tasks` folder of the `tools` module on your Gitlab instance.
* Copy the plans in `site-modules/tools/plans` to the `plans` folder of the `tools` module on your Gitlab instance.
* Add the `puppetlabs-bolt_shim`, `puppetlabs-puppet_agent` and `puppetlabs-apply_helpers` modules to the Puppetfile of your PE control-repo.

* Add the Puppet code in the Apply() block from `site-modules/tools/plans/timesync_code.pp` to a manifest in your PE control-repo, so that you could apply it to a node via PE if you wanted to.

<br/>**Step-by-step demo guide (Bolt only)**
1) Step into the bolt-timesync folder after cloning it with git:<br/>
`cd bolt-timesync`
2) Demonstrate the basic structure of a Bolt command:<br/>
`bolt command run 'mycommand' --node somenode`
3) Demonstrate how we can ping a server with Bolt (change 1.2.3.4 to the IP address of your Windows VM, and provide the correct username & password):<br/>
`bolt command run 'ping 8.8.8.8 -n 2' --nodes 1.2.3.4 --user vagrant --pass vagrant --transport winrm --no-ssl`
4) Talk about how you wouldn't want to have these long commandlines with all those parameters everytime, so it would be better to leverage the bolt Inventory file feature. First, show the inventory.yaml file:<br/>
`cat inventory.yaml`
5) Having pointed out that this same node can now be reference by the name `windows`, update the bolt command:<br/>
`bolt command run 'ping 8.8.8.8 -n 2' --nodes windows`
6) Switch the context to time synchronization. Let's say you'd want to leverage Bolt to easily sync the time on your servers, expecting the time settings are configured correctly everywhere:<br/>
`bolt command run 'w32tm /resync' --nodes windows`
7) Notice the output:<br/>

        Sending resync command to local computer
        The computer did not resync because no time data was available.
8) The command apparently didn't succeed, but w32tm still exits with errorlevel 0 so it looks like a successful command. This will be relevant later.
9) Let's have a look at the w32tm configuration on this node:<br/>
`bolt command run 'w32tm /query /peers' --nodes windows`<br/>
The output shows the server is misconfigured:<br/>

        STDOUT:
        #Peers: 1
    
        Peer: i.dont.exist
        State: Pending
        Time Remaining: 0.0000000s
        Mode: 0 (reserved)
        Stratum: 0 (unspecified)
        PeerPoll Interval: 0 (unspecified)
        HostPoll Interval: 0 (unspecified)`
10) Well, that is something we could fix with Bolt! Talk about how one *could* run a slew of `bolt command run` statements to fix this,but it's likely this problem would be present on more than just this one node. So, as a good sysadmin, we'd want to use a script to run all the commands on the node to clean up this mess. Let's have a look at the timesync.ps1 script we've made for this:<br/>
`cat timesync.ps1`
11) Looks pretty good! Let's use Bolt to run this on the node:<br/>
`bolt script run timesync.ps1 --nodes windows`<br/>

        STDOUT:
        Reconfiguring W32Time...
        The command completed successfully.

        Resyncing clock...
        Sending resync command to local computer
        The command completed successfully.

        Current time source:
        0.nl.pool.ntp.org

        All configured time sources:
        #Peers: 2

        Peer: 0.nl.pool.ntp.org
        State: Active
        Time Remaining: 1023.9535139s
        Mode: 3 (Client)
        Stratum: 2 (secondary reference - syncd by (S)NTP)
        PeerPoll Interval: 10 (1024s)
        HostPoll Interval: 10 (1024s)

        Peer: 1.nl.pool.ntp.org
        State: Active
        Time Remaining: 1023.9535139s
        Mode: 3 (Client)
        Stratum: 2 (secondary reference - syncd by (S)NTP)
        PeerPoll Interval: 10 (1024s)
        HostPoll Interval: 10 (1024s)
12) Nice! Now if only we could share this more easily with others... Time to turn this into a Puppet Task, so that others can use it, and we are able to use in directly in PE as well.<br/>
Wouldn't it be nice if we could pass parameters to the task, and have a description delivered with the task as well? We can do both quite easily with a Puppet Task.
13) First, we've taken our script and copied it to a module (which really is nothing more than a directory in Bolt), into a /tasks subdirectory of the module. We've also added an optional 'restart' parameter to it:<br/>
`cat site-modules/tools/tasks/timesync.ps1`
14) Next, we've added a bit of metadata to make it easier to work with the Task:<br/>
`cat site-modules/tools/tasks/timesync.json`
15) Tasks are automatically given the name of their script file, without the extension. So now we can ask Bolt what this Task does and what it needs:<br/>
`bolt task show tools::timesync`

        tools::timesync - Configures Windows Time via powershell

        USAGE:
        bolt task run --nodes <node-name> tools::timesync restart=<value>

        PARAMETERS:
        - restart: Boolean
            Restart the service after configuration

        MODULE:
        /root/site-modules/tools
16) Let's try this out!<br/>
`bolt task run --nodes windows tools::timesync restart=true`<br/>
Note that the output now shows the extra two lines for restarting the service:

        Restart parameter enabled, restarting Windows Time service
        Windows Time service restarted
17) So how could we easily let others use this too? Well, one option is to have a central fileshare and configure Bolt to always look there for modules (with --modulepath, or preconfiguring this in bolt.yaml). If you have Puppet Enterprise, all you need to do is copy the module to your Git server and add it to the Puppetfile, and the Tasks will show up in the Puppet Tasks GUI.<br/>
Navigate to the PE console to show that the Task is there, but don't run it.
18) So now we have this working, but what if we wanted to string multiple tasks together? Is there a good way to do this? Yes there is, and it's called Puppet Task Plans :-)<br/>
In the same tools module, we created a `plans` directory where we can put our plans. A simple one looks like this:<br/>
`cat site-modules/tools/plans/timesync.pp`
19) This plan simply runs the tools::timesync task, but with the restart parameter set to false, and then runs the (built-in) service task to restart the W32Time service. While this achieves the same end result, it does leverage the fact that Bolt will automatically halt the execution of the next task if the previous one failed. So now we don't have to script any of that into our original tools::timesync task anymore! Of course this is just a demo, but it shows the versatility.
20) Plans can be shipped with modules just as Tasks, and you use them in Bolt in a very similar way:<br/>
  `bolt plan show tools::timesync`

        tools::timesync

        USAGE:
        bolt plan run tools::timesync nodes=<value>

        PARAMETERS:
        - nodes: TargetSpec

        MODULE:
        /root/site-modules/tools  
21) And of course we're gonna try that out too:<br/>
  `bolt plan run --nodes windows tools::timesync`

        Starting: plan tools::timesync
        Starting: task tools::timesync on 1.2.3.4
        Finished: task tools::timesync with 0 failures in 2.71 sec
        Starting: task service on 1.2.3.4
        Finished: task service with 0 failures in 4.94 sec
        Finished: plan tools::timesync in 7.67 sec
        Plan completed successfully with no result
22) This shows a more high-level output compared to a task. If we want to see the output of the individual tasks, we could run the plan with the --verbose parameter. If you run a plan via PE, you can actually via the results of the plan and it's individual tasks directly in the PE console.
23) So now we've automated W32Time. Well, we've scripted it and professionalized how it's used, documented and shared. But Puppet has been doing automation of infrastructure components for years, in something called Infrastructure as Code, right? How does that fit in then? Well, we can actually leverage all of that rich automation for Bolt now too!
24) Let's first see if we can find a piece of existing automation for managing time on Windows. Navigate to https://forge.puppet.com and search for time, with the Operating System filter set to 'Windows'. In the results (about halfway down the page) you'll see a 'windowstime' module by the user 'ncorrare'. Click that module and you'll see that with this module, we would need only a couple of lines of IaC to automate this! So we want to try out this module now.
25) Click on the 'Dependencies' tab of the module and note that this module depends on 2 puppetlabs modules. We need to tell Bolt that we want to use this module and the 2 modules it depends on. We do this by putting them in a Puppetfile:<br/>
`cat Puppetfile`
1)  Let's install these 3 new modules:<br/>
`bolt puppetfile install`
27) Now we should have a way of applying those few lines of IaC to our demo node. In Bolt, we can do that in a Plan, using the Apply() function. It looks like this:<br/>
`cat site-modules/tools/plans/timesync_code.pp`<br/>
Basically the plan has 2 statements, the apply_prep() statement prepares the node for handling IaC (by installing the puppet agent), and the apply() statement will apply the block of IaC that it contains to the node. This bit of IaC has some more configuration in it (4 NTP servers, additional timesync flags), so we should see this cause changes when we apply it.
28) Let's try updating our node with this new configuration:<br/>
`bolt plan run --node windows tools::timesync_code`

        Starting: plan tools::timesync_code
        Starting: install puppet and gather facts on 1.2.3.4
        Finished: install puppet and gather facts with 0 failures in 6.51 sec
        Starting: apply catalog on 1.2.3.4
        Finished: apply catalog with 0 failures in 10.5 sec
        Finished: plan tools::timesync_code in 17.02 sec
        Plan completed successfully with no result
29)  (ignore the Hiera 4 deprecation warnings)<br/>
That seems to have worked well. Let's verify if the timesources have been updated:<br/>
`bolt command run 'w32tm /query /peers' --nodes windows`<br/>
Yep the output shows 4 NTP servers all configured correctly. We have now automated a component using Infrastructure as Code!
30) The IaC we used, is directly reusable by Puppet Enterprise to continuously enforce the correct configuration (of NTP on Windows in this case) across your estate. And since we have already used Bolt to apply some IaC on our node, the Puppet agent is already available there now. All we need to do to start continuous enforcement, is to activate the agent and point it to the PE master:<br/>
`bolt command run 'puppet config set server master.inf.puppet.vm' --nodes windows`<br/>
`bolt command run 'start-service puppet' --nodes windows`
31) Show the agent checking in to the master and show how you can enforce the time sync configuration by classifying the node with the same Puppet code.

<br/>**Optional section to run Tasks & Plans against PE with Bolt**

32) If we tell Bolt how it can connect to Puppet Enterprise, we get access to PE-managed nodes directly, and we don't need to worry about SSH/WinRm access & credentials anymore. To do this, configure the bolt.yaml with 4 properties (and have the 2 files we specify here):<br/>
`cat bolt.yaml`

        pcp:
          service-url: https://master.inf.puppet.vm:8143
          cacert: /etc/puppetlabs/puppet/ssl/certs/ca.pem
          token-file: /home/root/.puppetlabs/token
          task-environment: production
33) We can now reference PE-managed nodes using the pcp:// transport:<br/>
`bolt command run 'ping 8.8.8.8 -n 2' --nodes pcp://windows.puppet.vm`
34) This works for tasks and plans too:<br/>
`bolt plan run --node pcp://windows.puppet.vm tools::timesync_code`
35) Show how the results of the plan appear in the PE console, Tasks section, Plans tab.
