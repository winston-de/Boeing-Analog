using Toybox.Application;
using Toybox.WatchUi;

class BoeingWatchApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state) {
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
    }

    // Return the initial view of your application here
    function getInitialView() {
        return [new BoeingWatchView(), new AnalogDelegate()];
    }

    // New app settings have been received so trigger a UI update
    function onSettingsChanged() {
        WatchUi.requestUpdate();
    }

    // This method runs when a goal is triggered and the goal view is started.
    function getGoalView(goal) {
        // return [new BoeingWatchGoalView(goal)];
        //Nulled until further notice.......
        return null;
    }

}