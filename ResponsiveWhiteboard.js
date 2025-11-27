import React, { useMemo } from 'react';
import { View, Text, StyleSheet, useWindowDimensions } from 'react-native';

const ResponsiveWhiteboard = () => {
    const { width, height } = useWindowDimensions();

    const dynamicStyles = useMemo(() => {
        const baseSpacing = width * 0.04;
        const compactSpacing = baseSpacing * 0.5;
        const microSpacing = compactSpacing * 0.5;

        return {
            header: {
                paddingHorizontal: baseSpacing,
                paddingTop: compactSpacing,
                paddingBottom: compactSpacing,
                borderBottomWidth: width * 0.002,
            },
            brandText: {
                fontSize: width * 0.06,
                marginBottom: microSpacing,
            },
            subText: {
                fontSize: width * 0.032,
            },
            main: {
                paddingHorizontal: baseSpacing,
                paddingVertical: compactSpacing,
                gap: baseSpacing,
            },
            canvas: {
                borderRadius: width * 0.04,
                borderWidth: width * 0.003,
                paddingHorizontal: baseSpacing,
                paddingVertical: baseSpacing,
            },
            canvasTitle: {
                fontSize: width * 0.045,
                marginBottom: compactSpacing,
            },
            canvasHelper: {
                fontSize: width * 0.034,
                marginBottom: compactSpacing,
            },
            markerRow: {
                gap: compactSpacing,
            },
            marker: {
                height: height * 0.04,
                borderRadius: height * 0.02,
                paddingHorizontal: baseSpacing,
                justifyContent: 'center',
            },
            markerLabel: {
                fontSize: width * 0.032,
            },
            sidePanel: {
                paddingHorizontal: baseSpacing,
                paddingVertical: baseSpacing,
                borderRadius: width * 0.04,
                borderWidth: width * 0.0025,
                gap: compactSpacing,
            },
            sidePanelTitle: {
                fontSize: width * 0.04,
            },
            badgeRow: {
                gap: compactSpacing,
            },
            badge: {
                paddingHorizontal: baseSpacing,
                paddingVertical: microSpacing,
                borderRadius: width * 0.04,
                borderWidth: width * 0.002,
            },
            badgeText: {
                fontSize: width * 0.032,
            },
            footer: {
                paddingHorizontal: baseSpacing,
                paddingVertical: compactSpacing,
                borderTopWidth: width * 0.002,
            },
            footerText: {
                fontSize: width * 0.032,
            },
        };
    }, [width, height]);

    return (
        <View style={styles.container}>
            <View style={[styles.header, dynamicStyles.header]}>
                <Text style={[styles.brandText, dynamicStyles.brandText]}>Ideation Session</Text>
                <Text style={[styles.subText, dynamicStyles.subText]}>
                    Mock collaborative whiteboard designed for Android screens.
                </Text>
            </View>

            <View style={[styles.main, dynamicStyles.main]}>
                <View style={[styles.canvas, dynamicStyles.canvas]}>
                    <Text style={[styles.canvasTitle, dynamicStyles.canvasTitle]}>Sketch Space</Text>
                    <Text style={[styles.canvasHelper, dynamicStyles.canvasHelper]}>
                        Use gestures to draw, drop sticky notes, or import assets.
                    </Text>
                    <View style={[styles.markerRow, dynamicStyles.markerRow]}>
                        <View style={[styles.marker, dynamicStyles.marker, styles.markerPrimary]}>
                            <Text style={[styles.markerLabel, dynamicStyles.markerLabel]}>Marker</Text>
                        </View>
                        <View style={[styles.marker, dynamicStyles.marker, styles.markerSecondary]}>
                            <Text style={[styles.markerLabel, dynamicStyles.markerLabel]}>Highlighter</Text>
                        </View>
                        <View style={[styles.marker, dynamicStyles.marker, styles.markerAccent]}>
                            <Text style={[styles.markerLabel, dynamicStyles.markerLabel]}>Laser</Text>
                        </View>
                    </View>
                </View>

                <View style={[styles.sidePanel, dynamicStyles.sidePanel]}>
                    <Text style={[styles.sidePanelTitle, dynamicStyles.sidePanelTitle]}>Participants</Text>
                    <View style={[styles.badgeRow, dynamicStyles.badgeRow]}>
                        <View style={[styles.badge, dynamicStyles.badge]}>
                            <Text style={[styles.badgeText, dynamicStyles.badgeText]}>Ava</Text>
                        </View>
                        <View style={[styles.badge, dynamicStyles.badge]}>
                            <Text style={[styles.badgeText, dynamicStyles.badgeText]}>Liam</Text>
                        </View>
                        <View style={[styles.badge, dynamicStyles.badge]}>
                            <Text style={[styles.badgeText, dynamicStyles.badgeText]}>Noah</Text>
                        </View>
                    </View>
                    <Text style={[styles.canvasHelper, dynamicStyles.canvasHelper]}>
                        Tap a participant to follow their cursor in real time.
                    </Text>
                </View>
            </View>

            <View style={[styles.footer, dynamicStyles.footer]}>
                <Text style={[styles.footerText, dynamicStyles.footerText]}>
                    Auto-saving to shared workspace • Connection stable
                </Text>
            </View>
        </View>
    );
};

const styles = StyleSheet.create({
    container: {
        flex: 1,
        backgroundColor: '#0f172a',
        flexDirection: 'column',
    },
    header: {
        height: '10%',
        justifyContent: 'center',
        backgroundColor: '#1e293b',
    },
    brandText: {
        color: '#f8fafc',
        fontWeight: '600',
    },
    subText: {
        color: '#cbd5f5',
    },
    main: {
        flex: 1,
        flexDirection: 'row',
    },
    canvas: {
        flex: 1,
        backgroundColor: '#0b1120',
        justifyContent: 'flex-start',
        borderColor: '#38bdf8',
    },
    canvasTitle: {
        color: '#f8fafc',
        fontWeight: '600',
    },
    canvasHelper: {
        color: '#d1d5db',
    },
    markerRow: {
        flexDirection: 'row',
        alignItems: 'center',
    },
    marker: {
        flexDirection: 'row',
        alignItems: 'center',
    },
    markerLabel: {
        color: '#0b1120',
        fontWeight: '600',
    },
    markerPrimary: {
        backgroundColor: '#38bdf8',
    },
    markerSecondary: {
        backgroundColor: '#f472b6',
    },
    markerAccent: {
        backgroundColor: '#facc15',
    },
    sidePanel: {
        flex: 0.35,
        backgroundColor: '#111827',
        borderColor: '#475569',
    },
    sidePanelTitle: {
        color: '#f8fafc',
        fontWeight: '600',
    },
    badgeRow: {
        flexDirection: 'row',
        flexWrap: 'wrap',
        alignItems: 'center',
    },
    badge: {
        backgroundColor: '#1e293b',
        borderColor: '#38bdf8',
    },
    badgeText: {
        color: '#f8fafc',
        fontWeight: '500',
    },
    footer: {
        height: '5%',
        justifyContent: 'center',
        backgroundColor: '#1e293b',
        borderTopColor: '#475569',
    },
    footerText: {
        color: '#cbd5f5',
    },
});

export default ResponsiveWhiteboard;
