import { StyleSheet, useColorScheme } from 'react-native';
import { WebView } from 'react-native-webview';
import { SafeAreaView } from 'react-native-safe-area-context';
import React from 'react';

export default function App() {
  const colorScheme = useColorScheme();
  const backgroundColor = colorScheme === 'dark' ? '#000000' : '#ffffff';

  return (
    <SafeAreaView style={[styles.container, { backgroundColor }]}>
      <WebView
        style={styles.webview}
        source={{ uri: 'https://propeak.algorisys.com/' }}
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  webview: {
    flex: 1,
  },
});
