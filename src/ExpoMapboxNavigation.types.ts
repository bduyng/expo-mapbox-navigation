import { ViewProps } from 'react-native';
export type ChangeEventPayload = {
  value: string;
};

export type ExpoMapboxNavigationViewProps = {
  name?: string;
} & ViewProps;
