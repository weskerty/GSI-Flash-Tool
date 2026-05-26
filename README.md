<div style="text-align:center;"
<p align="center">
<img src="https://github.com/user-attachments/assets/1a23e163-4c00-49e5-bccb-24d52ec8d65c" alt="Termuxito" width="100">
<h1 align="center">Installer GSI</h1>
</div>

<p>This batch script simplifies the process of flashing a Generic System Image (GSI) on your Android device. </p>




https://github.com/user-attachments/assets/00d4cba0-f539-4e29-b725-4d8dd7dcca2f




<h1>Run in Linux: </h1>
    
    bash <(curl https://raw.githubusercontent.com/weskerty/GSI-Flash-Tool/refs/heads/main/RUN-Linux.sh) 
    

<h2>📋 Requirements</h2>

<details>
  <summary>📱 Android device with unlocked bootloader</summary>
  <p>Trying to run it will fail if it's not unlocked. Each device has its own unlocking method. </p>



<a href="https://github.com/zenfyrdev/bootloader-unlock-wall-of-shame#-avoid-at-all-costs">
    🔗 Find yours here ↗️
  </a>
  
</details>

<details>
  <summary>📦 GSI ROM</summary>
  Download the GSI you prefer. <br><br>

  <a href="https://github.com/TrebleDroid/treble_experimentations/wiki/Generic-System-Image-%28GSI%29-list">
    🔗 View GSI List
  </a>
  <br> 
  Normally, if your phone is stuck on a certain version, you'll need to use a GSI with that version. Higher versions might work, but they require patches to function. For example, if Android 13+ WiFi is not detected, this can be fixed with ADB.
  
</details>

<details>
  <summary>🛠️ Install ADB and Fastboot tools on PC</summary>
   <br>
   <h3>Arch Based</h3>

    
    sudo pacman -Syu git android-tools android-udev --needed --noconfirm
    

  
  <br>
    
   <h3>Debian Based</h3>

    
    sudo apt-get install git android-sdk-platform-tools -y
    

  
  <br>
    
<h3>Windows</h3>

    
    winget install Google.PlatformTools --source winget
    winget install Git.Git --source winget
    

  
  <!--
  --scope machine -->
  
  <br>
  <p> Windows requires Google's ADB drivers, as well as drivers from the processor and device manufacturers. <br>
     1- Google ADB Drivers 2- MTK/QL/etc Drivers 3- Xiaomi/etc Drivers </p>

   
</details>

<details>
  <summary>📂 Required firmware files</summary>
  Place the required firmware files in the same directory as the script:
  <ul>
    <li><code>vbmeta.img</code></li>
    <li><code>vbmeta_system.img</code></li>
    <li><code>vbmeta_vendor.img</code></li>
    <li><code>vendor_boot.img</code> or <code>boot.img</code></li>
  </ul>
<p>These files are only needed if it's your first time and you haven't disabled vbmeta yet. <br>

are optional if you want to install KSU. The only thing really required is your GSI.img.</p>

<br>
<a href="https://www.needrom.com/">
    🔗 Find your Firmware ↗️
  </a>
  
</details>

<h2>Tested On: </h2>

<table>
  <tr>
    <td><img width="100" src="https://github.com/user-attachments/assets/b7c329e2-6664-4416-a77f-a21cafd96946"></td>
    <td><img width="100" src=""></td>
  </tr>
  <tr>
    <td>Xiaomi Taiko</td>
    <td></td>
  </tr>
    <tr>
      <td><img width="400" src="" /></td>
      <td><img width="400" src="" /></td>
    </tr>

  </table>


<h2>Disclaimer:</h2>

<p>This script is provided as-is, without any warranty. Use it at your own risk. Make sure you have a backup of your device before flashing a GSI.</p>

<details>
  <summary>📱 Repair a Damaged System - Phone Won't Start</summary>
  <p>This usually happens because you didn't attach the vmbeta files and other necessary files to allow booting from a ROM other than the original. Or you tried to force it with the bootloader locked.</p>
<p>The solution is easy, depending on the device. This tool doesn't write to sensitive partitions that can't be easily recovered.</p>

<h3>Example Xiaomi:</h3>
<p>For Xiaomi it's easy, just search for your device name; it should match the keyword. The script displays it at startup, so check there.</p>

<a href="https://mifirm.net/">
    🔗 Find your Xiaomi Firmware ↗️
  </a>

  <p>Choose your correct variant, usually Xiaomi Global (Chinese and Indian version cannot be unlocked)
  <br>
   Once downloaded, extract the file using 7-Zip or your preferred compression program. Then, within the folder, locate the file "flash_all" with the extension <code>.bat</code> for Windows or <code>.sh</code> for Linux.

Run this file, then connect your phone in fastboot mode (press and hold the power button and volume down button until FASTBOOT appears on the screen).
<br>
When it finishes, it will restart and turn on with the original Xiaomi firmware (MIUI/HyperOS).

  </p>

<h2>What if I don't have a Xiaomi?</h2>

<p>In that case, you'll need to find your phone's firmware somewhere and extract the super.img file inside the zip file.Then reboot into fastboot and run: <code>fastboot flash super /path/super.img</code> And when it's over: <code>fastboot reboot</code> <br> And it should boot into the original system if you only modified the GSI. If you modified the boot partition and other partitions, you'll also have to reinstall the originals, in the same way.</p>

<a href="https://www.needrom.com/">
    🔗 Find your Firmware ↗️
  </a>

</details>
