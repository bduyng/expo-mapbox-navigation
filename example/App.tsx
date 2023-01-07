import { View } from 'react-native';

import * as ExpoMapboxNavigation from 'expo-mapbox-navigation';

export default function App() {
  return (
    <View style={{ flex: 1 }}>
      <ExpoMapboxNavigation.ExpoMapboxNavigationView
        style={{ flex: 1 }}
        // onRouteProgressChange={event => {
        //   const { distanceTraveled, durationRemaining, fractionTraveled, distanceRemaining } =
        //     event.nativeEvent;
        // }}
        // onError={event => {
        //   const { message } = event.nativeEvent;
        // }}
        onCancelNavigation={() => {
          // User tapped the "X" cancel button in the nav UI
          // or canceled via the OS system tray on android.
          // Do whatever you need to here.
          console.log('onCancelNavigation');
        }}
        // onArrive={() => {
        //   // Called when you arrive at the destination.
        // }}
      />
    </View>
  );
}
