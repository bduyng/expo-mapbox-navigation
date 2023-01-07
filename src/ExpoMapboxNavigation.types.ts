import { ViewProps } from 'react-native';
export type ChangeEventPayload = {
  value: string;
};

export type ExpoMapboxNavigationViewProps = {
  name?: string;
  onArrive?(): void;
  onError?(): void;
  onCancelNavigation?(): void;
  onLocationChange?(): void;
  onRouteProgressChange?(): void;
} & ViewProps;
