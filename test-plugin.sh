rm -rf ./expo-mapbox-navigation-0.1.0.tgz && npm run prepare && npm pack && cd example && npm install ../expo-mapbox-navigation-0.1.0.tgz && npx expo prebuild && npx pod-install