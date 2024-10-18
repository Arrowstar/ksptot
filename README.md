# KSP Trajectory Optimization Tool 
The KSP Trajectory Optimization Tool (KSPTOT) is a stand-alone, MATLAB-based software toolkit for advanced KSP pilots and astrodynamicists.  Contained within this suite are tools for end-to-end spacecraft and launch vehicle mission design, gravity assist maneuver design, rendezvous maneuver design, celestial body data, and more.
###### KSPTOT runs via the MATLAB Compiler Runtime.  Ownership of MATLAB is not required to use KSPTOT.
![Launch Vehicle Designer](https://i.imgur.com/payZQHR.png)
## Included Tools & Features
KSPTOT contains the following software tools:

 1. **Launch Vehicle Designer (LVD):** A fully featured, end-to-end, launch vehicle and spacecraft mission design tool capable of modeling complex gravity, atmospheric drag, solar radiation pressure, and lift forces.  LVD can also model vehicle electrical systems, handle complex staging and propellant transfer/flow schemes, and model multi-vehicle simulations.  LVD includes a fully featured geometry suite and textual/graphical data analysis package.  Control laws optimized in LVD can be implemented in KSP itself via a provided, easy-to-use kOS script.
 2. **Multi-Flyby Maneuver Sequencer:**  A simplified tool for rapid exploration of complex spacecraft mission trade spaces featuring gravity assist maneuvers.  Users specify the departure body, arrival body, and waypoints and MFMS figures out the rest.
 3.  **Porkchop Plot Generator:** A quick, easy-to-use tool that computes and displays porkchop plots between various celestial bodies.  Also provides ballistic transfer data and maneuver estimation between bodies.
 4.  **Rendezvous Maneuver Sequencer:** Another quick and simple tool that computes optimized rendezvous and phasing maneuvers between two orbits.
 5. **Celestial Body Catalog** Displays pertinent data for all celestial bodies currently loaded, including orbit and rotational data, atmospheric data, and graphical display.
 6. **KSPTOTConnect Plugin:**  This plugin for KSP allows users to create celestial body database files ("bodies.ini" files), import spacecraft orbits and vehicle masses from KSP, and retrieve data from KSP.

## Download & Installation Instructions
#### To install and run KSPTOT on **Windows**, do the following:
1.  Download the [Windows 64-bit 2022a MATLAB Compiler Runtime (MCR)](https://www.mathworks.com/products/compiler/matlab-runtime.html).
2.  Install the MCR package on your computer. **You may need to restart your PC after installing in order to use KSPTOT.**
3.  **Download the KSPTOT package.
4.  Unzip the KSPTOT package to a directory of your choosing.
5.  **Copy the KSPTOTConnect folder to your KSP Gamedata folder**.
6.  **Copy the Ships folder to your KSP folder** (if you use kOS).
7.  Run the KSPTOT application.
8.  To update from a previous version, just repeat steps 3-6. There is no need to re-download the MCR.
#### **Mac/Linux Users: Follow these instructions instead.**
1.  (Mac only): [Download VirtualBox for OS X hosts.](https://www.virtualbox.org/wiki/Downloads) Install according to the VirtualBox instructions. Setup and install a distribution of Linux as a virtual machine within VirtualBox. (Ex: [Ubuntu](https://www.ubuntu.com/download/desktop)) All instructions from here on down will reference the virtual machine and it's Linux operating system, not the Mac system.
2.  Download the [Linux 64-bit 2022a MATLAB Compiler Runtime (MCR).](https://www.mathworks.com/products/compiler/matlab-runtime.html)
3.  Install the MCR package on your computer. **You may need to restart your PC after installing in order to use KSPTOT.**
    1.  You MUST install the MCR to **"/usr/local/MATLAB/R2022a/"!** The software will not work correctly if this is not done.
4.  **Download the KSPTOT Package.**
5.  Unzip the KSPTOT package to a directory of your choosing.
6.  Set the execution bit on the run script and the executable itself. Using the following console command:
    1.  _chmod +x run_KSPTrajectoryOptimizationTool.sh KSPTrajectoryOptimizationTool_
7.  **Copy the KSPTOTConnect folder to your KSP Gamedata folder**.
8.  **Copy the Ships folder to your KSP folder** (if you use kOS).
9.  From within the directory where you unpacked KSPTOT, run "**./run_KSPTrajectoryOptimizationTool.sh /usr/local/MATLAB/R2022a/**" to launch KSPTOT.
10.  To update from a previous version, just repeat steps 4-6. There is no need to re-download the MCR.
11.  For addition detail, see [here](https://finitemonkeys.org/ksptot_on_linux).  
## Buy Me a Coffee
KSP Trajectory Optimization Tool has always been free, is free today, and will always be free to download and use. It is one of my most enjoyable hobbies and I consider it my gift to the KSP Community and developers for providing me with many hours of enjoyment. Over the years, though, a number of individuals have asked about donations as a way to say "thank you" for the hundreds (or even thousands) of hours that have gone into the development of KSPTOT. For those who wish to do so, I have a [Ko-Fi account](https://ko-fi.com/home/about2) that makes just that possible.

[![](https://i.imgur.com/pFX1IYV.png)](https://ko-fi.com/arrowstar)

To use, just click the "Buy Me a Coffee" button. You'll be taken to a page where you can enter an amount (in units of $3), a message, and make it public or private.

As a disclaimer, such donations don't imply any agreement for me to provide you with goods or services. (You already have the software!) They are merely another way for you to say "Thank You" and are completely optional and voluntary.

[![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=Arrowstar/ksptot/tree/v1.6.10&file=projectMain.m) 
