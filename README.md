# Demonstrating the Puppet Bolt automation journey with NTP

Perform these preparatory steps first for this demo:
* Spin up a Windows VM and ensure you can reach it via WinRM (run `winrm quickconfig` if needed)
* Change the Win32Time settings to sync to a non-existing server:<br/>
  `w32tm /config /update /manualpeerlist:"i.dont.exist"`<br/>
  (You will need to re-run this command before a new demo to get back to the initial demo state)
* Clone this repo into a demo folder:<br/>
  `git clone https://github.com/kreeuwijk/bolt-timesync`
* Update the `Boltdir/inventory.yaml` file:
    * Update the IP address to the IP of your Windows VM
    * Update the username & password for the WinRM credentials you're using

To enable the later part of the demo where you integrate with PE, follow these steps: 
* Update the `Boltdir/bolt.yaml` file:
    * Update the service-url to point to your PE master
    * Ensure you have a copy of the PE Master CA certificate and specify the path to where you have it stored
    * Ensure you have a copy of the PE Master RBAC token and specify the path to where you have it stored. If you don't have one yet, run `puppet access login` on the master to generate one.
* Ensure you have a `tools` module on your Gitlab instance used by PE. If you don't have a `tools` module, create an new one and add it to your control-repo's Puppetfile. Ensure the module has a `tasks` and a `plans` folder.
* Copy the tasks in `Boltdir/modules/tools/tasks` to the `tasks` folder of the `tools` module on your Gitlab instance.
* Copy the plans in `Boltdir/modules/tools/plans` to the `plans` folder of the `tools` module on your Gitlab instance.
* Add the `puppetlabs-bolt_shim` module to the Puppetfile of your PE control-repo

Step-by-step demo guide, part 1 (Bolt only):
  1) Step into the bolt-timesync folder after cloning it with git:<br/>
  `cd bolt-timesync`
  2) Demonstrate the basic structure of a Bolt command:<br/>
  `bolt command run 'mycommand' --node somenode`
  3) Demonstrate how we can ping a server with Bolt (change 1.2.3.4 to the IP address of your Windows VM, and provide the correct username & password):<br/>
  `bolt command run 'ping 8.8.8.8 -n 2' --nodes 1.2.3.4 --user vagrant --pass vagrant --transport winrm --no-ssl`
  4) Talk about how you wouldn't want to have these long commandlines with all those parameters everytime, so it would be better to leverage the bolt Inventory file feature. First, show the inventory.yaml file:<br/>
  `cat Boltdir/inventory.yaml`
  5) Having pointed out that this same node can now be reference by the name `winnode1`, update the bolt command:<br/>
  `bolt command run 'ping 8.8.8.8 -n 2' --nodes winnode1`
  6) Switch the context to time synchronization. Let's say you'd want to leverage Bolt to easily sync the time on your servers, expecting the time settings are configured correctly everywhere:<br/>
  `bolt command run 'w32tm /resync' --nodes winnode1`
  7) Notice the output:<br/>
  `Sending resync command to local computer`<br/>
  `The computer did not resync because no time data was available.`<br/>
  The command apparently didn't succeed, but w32tm still exits with errorlevel 0 so it looks like a successful command. This will be relevant later.
  8) 


