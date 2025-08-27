# interior_demo

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


TODO LIST:

every object should contain real world position of every corner and edge. (make it accessable)
it needs to be like a puzzle instead complex fucking math everywhere so AI can get info and add-remove


inspect ground rules of the carpenting and check data
objectify every single fucking thing and add features to it so it'll be accessible when need. 


ok like demo flaw right?

add walls

each wall is a group and universe, each wall has it's position in the 1 universe

walls have start points, bottom is can be reference for lower cabinets and top can be reference for upper


and we start building from there

let's say we add 2 door cabinet, we gonna add drawer. bottom-front-right of the 2 door cabinet should match with bottom-front-left of drawer.

and we finished first wall! aight, then we added top etc. but when started to the next wall, the user of the app should know
either you gonna give space (create space object and make the user master of it) for end of the 1st wall or beggining of the 2nd wall


then we can set that conflict once and for all. or ai can add space by itself, since this app not for design but for design preview.

ok. so here is sum

wall1 -> cabinet -> cabinet -> drawer -> space -> cabinet

wall2 -> space -> cabinet -> cabinet -> cabinet -> flush -> cabinet

all you need is attach the motherfuckers with each other! 

of course there will be asserts like overflow warnings, suggestions etc

then later, we gonna make everything a model and integrate gpt5 to it. we gonna instruct it to attach objects, learn our structure and 
help users to make better kitchens!