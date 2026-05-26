# SpeleoLoc

SpeleoLoc is an application that helps cavers to navigate underground and to document cave systems using QR codes to identify places in caves.

## Project goals

One of the main goals of SpeleoLoc is underground positioning, designed to help exploration teams navigate more easily through complex cave systems and to help during all exploration phases. Another key goal is to simplify cave documentation and automate the information flow, both during exploration and in later analysis.

The system is based on placing QR code labels at points of interest inside caves, in both already known areas and newly explored sections. QR codes are scanned in the app and linked to corresponding points on existing maps, creating a practical form of underground "geolocation".

Each mapped point can store additional information, including text and media. After data synchronization between mobile devices, other teams can later identify their exact position on system maps, review existing information, and add new observations.

Another component of the system is placing QR codes at the entrance of explored caves. The payload in these QR codes is a weblink that can be scanned both with SpeleoLoc but could optionally be linked with a website in order to open on any mobile device online for broader access to relevant information.

## Current status
The application is under development, in an early beta stage / alpha - some of the functionality is not tested extensively.

## Docs
Check [user documentation](docs/README.md) (might not be always up to date).

## Future development
- Dedicated web server for synchronization (now sync is done by sending files / FTP).
- In cave sync between devices via bluetooth
- hardware BLE beacon based point detection
- Surface dynamic maps