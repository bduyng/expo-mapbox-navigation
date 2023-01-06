import {
  ConfigPlugin,
  createRunOncePlugin,
  withDangerousMod,
  withInfoPlist,
} from '@expo/config-plugins';
import { promises } from 'fs';
import path from 'path';

import { mergeContents, removeGeneratedContents } from './generateCode';

const pkg = require('expo-mapbox-navigation/package.json');

const LOCATION_WHEN_IN_USE_USAGE = 'Allow $(PRODUCT_NAME) to use your location';
const LOCATION_ALWAYS_AND_WHEN_IN_USE_USAGE = 'Allow $(PRODUCT_NAME) to use your location';
const LOCATION_ALWAYS_USAGE = 'Allow $(PRODUCT_NAME) to use your location';

type InstallerBlockName = 'pre' | 'post';

export function addInstallerBlock(src: string, blockName: InstallerBlockName): string {
  const matchBlock = new RegExp(`${blockName}_install do \\|installer\\|`);
  const tag = `${blockName}_installer`;
  for (const line of src.split('\n')) {
    const contents = line.trim();
    // Ignore comments
    if (!contents.startsWith('#')) {
      // Prevent adding the block if it exists outside of comments.
      if (contents.match(matchBlock)) {
        // This helps to still allow revisions, since we enabled the block previously.
        // Only continue if the generated block exists...
        const modified = removeGeneratedContents(src, tag);
        if (!modified) {
          return src;
        }
      }
    }
  }

  return mergeContents({
    tag,
    src,
    newSrc: [`  ${blockName}_install do |installer|`, '  end'].join('\n'),
    anchor: /use_react_native/,
    // We can't go after the use_react_native block because it might have parameters, causing it to be multi-line (see react-native template).
    offset: 0,
    comment: '#',
  }).contents;
}

export function addMapboxInstallerBlock(src: string, blockName: InstallerBlockName): string {
  return mergeContents({
    tag: `expo-mapbox-navigation-${blockName}_installer`,
    src,
    newSrc: `    $RNMBNAV.${blockName}_install(installer)`,
    anchor: new RegExp(`^\\s*${blockName}_install do \\|installer\\|`),
    offset: 1,
    comment: '#',
  }).contents;
}

/**
 * Dangerously adds the custom installer hooks to the Podfile.
 * In the future this should be removed in favor of some custom hooks provided by Expo autolinking.
 *
 * https://github.com/rnmapbox/maps/blob/main/ios/install.md#react-native--0600
 * @param config
 * @returns
 */
const withCocoaPodsInstallerBlocks: ConfigPlugin = _config => {
  return withDangerousMod(_config, [
    'ios',
    async config => {
      const file = path.join(config.modRequest.platformProjectRoot, 'Podfile');

      const contents = await promises.readFile(file, 'utf8');

      await promises.writeFile(file, applyCocoaPodsModifications(contents), 'utf-8');
      return config;
    },
  ]);
};

export function applyCocoaPodsModifications(contents: string): string {
  // Ensure installer blocks exist
  let src = contents;

  // FIXME: a better way here?
  src = src.replace(':deterministic_uuids => false', ':deterministic_uuids => false,');
  return mergeContents({
    tag: `expo-mapbox-navigation-disable_input_output_paths`,
    src,
    newSrc: `  :disable_input_output_paths => true`,
    anchor: ':deterministic_uuids => false,',
    offset: 1,
    comment: '#',
  }).contents;
}

const withMapboxNavigation: ConfigPlugin<
  {
    whenInUseUsageDescription?: string;
    alwaysAndWhenInUseUsageDescription?: string;
    alwaysUsageDescription?: string;
  } | void
> = (
  config,
  { whenInUseUsageDescription, alwaysAndWhenInUseUsageDescription, alwaysUsageDescription } = {}
) => {
  config = withInfoPlist(config, config => {
    config.modResults.NSLocationWhenInUseUsageDescription =
      whenInUseUsageDescription ||
      config.modResults.NSLocationWhenInUseUsageDescription ||
      LOCATION_WHEN_IN_USE_USAGE;
    config.modResults.NSLocationAlwaysAndWhenInUseUsageDescription =
      alwaysAndWhenInUseUsageDescription ||
      config.modResults.NSLocationAlwaysAndWhenInUseUsageDescription ||
      LOCATION_ALWAYS_AND_WHEN_IN_USE_USAGE;
    config.modResults.NSLocationAlwaysUsageDescription =
      alwaysUsageDescription ||
      config.modResults.NSLocationAlwaysUsageDescription ||
      LOCATION_ALWAYS_USAGE;

    return config;
  });
  return withCocoaPodsInstallerBlocks(config);

  // FIXME:
  // config = AndroidConfig.Permissions.withPermissions(config, [
  //   'android.permission.CAMERA',
  //   // Optional
  //   'android.permission.RECORD_AUDIO',
  // ]);

  // return withAndroidCameraGradle(config);
};

export default createRunOncePlugin(withMapboxNavigation, pkg.name, pkg.version);
