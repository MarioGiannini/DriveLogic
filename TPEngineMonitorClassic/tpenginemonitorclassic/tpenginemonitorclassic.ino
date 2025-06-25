#include "BluetoothSerial.h"

////////////////////////////////////////////////////////////////////////////////////////
// maxDatapointsToSend defines the maximum number of datapoints to send at once (0 means unlimited), if you want smaller packets.
// For example, setting maxDatapointsToSend to 3 means buildBuffer will put the first 3 data points in the buffer, and the next call
// to buildBuffer will put the next 3 data points in the buffer, and so on.  Basically, it lets you partition the data points amid multiple sends.
int maxDatapointsToSend = 0; 

// MAXSETTINGS is the maximumnumber of settings used
#define MAXSETTINGS 64

// MAXDATAPOINTS is the maximum combined data points for an EFI and the common datapoints combined.
#define MAXDATAPOINTS 256

// MAXBUFFSIZE defines the maximum transmit buffer size.  Should be large enough to hold all datapoints as strings
#define MAXBUFFSIZE 8192 // MG: Issue 000836: Implement Data Format feature (increase buffer size)

// REFRESH_INTERVAL_MS controls whether the loop() does anything or not.
#define REFRESH_INTERVAL_MS 16

int totalDatapointsGlobal = 0; // MG: Made this global.  Only an issue if EFIDevice were to change mid-program

#define APPVERSION "1.1.0"
// 1.1.0 changed the protocol to support SETTINGS and data conversion with convertUnitType()
// 1.0.0 was the first time versioning was introduced
////////////////////////////////////////////////////////////////////////////////////////

TaskHandle_t BluetoothTaskHandle;
TaskHandle_t StringManipulationTaskHandle;

// EFIDevice defines the demo data to include for a specific type of EFI
String EFIDevice = "HOLLEYTERMX2"; // HALTECH2 or MEGASQUIRT

//#define USE_PIN // Uncomment this to use PIN during pairing. The pin is specified on the line below
const char *pin = "1234"; // Change this to more secure PIN.

String device_name = "DriveLogic";

static unsigned long nextRefreshTime = 0;
static char buffer[ MAXBUFFSIZE ];

int bufferOffset = 0;
String received;

// MG: Issue	0000836: Implement Data Format feature (Implement conversions utilizing Data Format settings)
enum UnitType {
    UT_ASIS = 0, 
    UT_MPH = 1, 
    UT_KPH = 2, 
    UT_FAHRENHEIT = 3, 
    UT_CELSIUS = 4, 
    UT_PSI = 5, 
    UT_KPA = 6, 
    UT_AFR = 7, 
    UT_LAMBDA = 8, 
    UT_BAROCALC = 9,
    UT_LASTENTRY = 10
};

const char* unitTypeString[] = {
  "UT_ASIS",
  "UT_MPH",
  "UT_KPH",
  "UT_FAHRENHEIT",
  "UT_CELSIUS",
  "UT_PSI",
  "UT_KPA",
  "UT_AFR",
  "UT_LAMBDA",
  "UT_BAROCALC",
  "UT_LASTENTRY",
};

enum UnitType requestedUnitType [ UT_LASTENTRY ] = { UT_ASIS, UT_MPH, 
    UT_KPH, 
    UT_FAHRENHEIT, 
    UT_CELSIUS, 
    UT_PSI, 
    UT_KPA, 
    UT_AFR, 
    UT_LAMBDA, 
    UT_BAROCALC};

typedef struct {
  const char* label; // Note: label must be unique in list of all data points in arpCombinedDataPoints
  float value, min, max, warnlow, warnhigh;
  const char* type;
  bool included;
  int decimals;
  const char* startCaption;
  const char* endCaption;
  enum UnitType unitType; // MG: Issue	0000836: Implement Data Format feature

  // Data below is for creating demo values
  float demo_dir;
} DATAPOINT;

DATAPOINT * arpCombinedDataPoints[MAXDATAPOINTS]; // This demo combines EFI datapoints and common datapoints into am array of pointers to DATAPOINTS (arp means array of pointers)

typedef struct {
  char* key;
  char* value;
} SETTING;

SETTING settings[ MAXSETTINGS ]; // All NULLs, since it's a globals

// Below are data arrays for demonstration and default values, created via Excel.  Update Excel, then copy ad paste the new arrays
DATAPOINT HolleyDemo[] = {
{"HIDE", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 1}, 
// {NULL, 0, 0, 0, 0, 0, NULL, false, 0, NULL, NULL, UT_ASIS, 0},  // Uncomment to truncate array for small set data transmission testing
{"TMG", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 2}, 
{"BST", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 3}, 
{"AFRL", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 4}, 
{"AFRR", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 5}, 
{"AFRA", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 6}, 
{"ECO", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 7}, 
{"BAT", 0, 0, 15, 10, 14, "G", true, 1, "L", "H", UT_ASIS, 0.5}, 
{"OIL", 0, 0, 100, 25, 75, "G", true, 0, "L", "H", UT_PSI, 1}, 
{"IAT", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 1}, 
{"FPR", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 2}, 
{"CLT", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 3}, 
{"TPS", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 4}, 
{"TRN", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 5}, 
{"TRSP", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 6}, 
{"TAFR", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 7}, 
{"RANG", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 8}, 
{"IACP", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 9}, 
{"GEAR", 0, 0, 7, 0, 7, "G", true, 0, "", "", UT_ASIS, 0.01}, 
{"SEN1", 0, 0, 5, 0, 5, "S", true, 0, "", "", UT_ASIS, 0.25}, 
{"SEN2", 0, 0, 5, 0, 5, "S", true, 0, "", "", UT_ASIS, 0.25}, 
{"SEN3", 0, 0, 5, 0, 5, "S", true, 0, "", "", UT_ASIS, 0.25}, 
{"SEN4", 0, 0, 5, 0, 5, "S", true, 0, "", "", UT_ASIS, 0.25}, 
{"SEN5", 0, 0, 5, 0, 5, "S", true, 0, "", "", UT_ASIS, 0.25}, 
{"SEN6", 0, 0, 5, 0, 5, "S", true, 0, "", "", UT_ASIS, 0.25}, 
{"SEN7", 0, 0, 5, 0, 5, "S", true, 0, "", "", UT_ASIS, 0.25}, 
{"SEN8", 0, 0, 5, 0, 5, "S", true, 0, "", "", UT_ASIS, 0.25}, 
{"SEN9", 0, 0, 5, 0, 5, "S", true, 0, "", "", UT_ASIS, 0.25}, 
{"SEN10", 0, 0, 5, 0, 5, "S", true, 0, "", "", UT_ASIS, 0.25}, 
{"SEN11", 0, 0, 5, 0, 5, "S", true, 0, "", "", UT_ASIS, 0.25}, 
{"SEN12", 0, 0, 5, 0, 5, "S", true, 0, "", "", UT_ASIS, 0.25}, 
{"SEN13", 0, 0, 5, 0, 5, "S", true, 0, "", "", UT_ASIS, 0.25}, 
{"SEN14", 0, 0, 5, 0, 5, "S", true, 0, "", "", UT_ASIS, 0.25}, 
{"SEN15", 0, 0, 5, 0, 5, "S", true, 0, "", "", UT_ASIS, 0.25}, 
{"SEN16", 0, 0, 5, 0, 5, "S", true, 0, "", "", UT_ASIS, 0.25}, 
{"SEN17", 0, 0, 5, 0, 5, "S", true, 0, "", "", UT_ASIS, 0.25}, 
{"SEN18", 0, 0, 5, 0, 5, "S", true, 0, "", "", UT_ASIS, 0.25}, 
{"SEN19", 0, 0, 5, 0, 5, "S", true, 0, "", "", UT_ASIS, 0.25}, 
{"SEN20", 0, 0, 5, 0, 5, "S", true, 0, "", "", UT_ASIS, 0.25}, 
{"SEN21", 0, 0, 5, 0, 5, "S", true, 0, "", "", UT_ASIS, 0.25}, 
{"SEN22", 0, 0, 5, 0, 5, "S", true, 0, "", "", UT_ASIS, 0.25}, 
{"SEN23", 0, 0, 5, 0, 5, "S", true, 0, "", "", UT_ASIS, 0.25}, 
{"SEN24", 0, 0, 5, 0, 5, "S", true, 0, "", "", UT_ASIS, 0.25}, 
{"SEN25", 0, 0, 5, 0, 5, "S", true, 0, "", "", UT_ASIS, 0.25}, 
{NULL, 0, 0, 0, 0, 0, NULL, false, 0, NULL, NULL, UT_ASIS, 0}};

DATAPOINT HalTech2Demo[] = {
{"HIDE", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 1}, 
// {NULL, 0, 0, 0, 0, 0, NULL, false, 0, NULL, NULL, UT_ASIS, 0},  // Uncomment to truncate array for small set data transmission testing
{"BST", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 2}, 
{"BAT", 0, 0, 15, 10, 14, "G", true, 1, "", "", UT_ASIS, 3}, 
{"OIL", 0, 0, 100, 25, 75, "G", true, 0, "", "", UT_PSI, 4}, 
{"OILT", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_FAHRENHEIT, 5}, 
{"IAT", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 6}, 
{"FPR", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 7}, 
{"CLT", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 8}, 
{"TPS", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 9}, 
{"EGT1", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 10}, 
{"EGT2", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 11}, 
{"E85", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 12}, 
{"GEAR", 0, 0, 7, 0, 7, "G", true, 0, "", "", UT_ASIS, 0.01}, 
{"SEN1", 0, 0, 5, 0, 5, "S", true, 0, "", "", UT_ASIS, 0.25}, 
{"SEN2", 0, 0, 5, 0, 5, "S", true, 0, "", "", UT_ASIS, 0.25}, 
{"SEN3", 0, 0, 5, 0, 5, "S", true, 0, "", "", UT_ASIS, 0.25}, 
{"SEN4", 0, 0, 5, 0, 5, "S", true, 0, "", "", UT_ASIS, 0.25}, 
{"SEN5", 0, 0, 5, 0, 5, "S", true, 0, "", "", UT_ASIS, 0.25}, 
{"SEN6", 0, 0, 5, 0, 5, "S", true, 0, "", "", UT_ASIS, 0.25}, 
{"SEN7", 0, 0, 5, 0, 5, "S", true, 0, "", "", UT_ASIS, 0.25}, 
{"SEN8", 0, 0, 5, 0, 5, "S", true, 0, "", "", UT_ASIS, 0.25}, 
{"SEN9", 0, 0, 5, 0, 5, "S", true, 0, "", "", UT_ASIS, 0.25}, 
{"SEN10", 0, 0, 5, 0, 5, "S", true, 0, "", "", UT_ASIS, 0.25}, 
{"LAM1", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 1}, 
{"LAM2", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 2}, 
{"LAM3", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 3}, 
{"LAM4", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 0.01}, 
{"LAMO", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 1}, 
{"LB1", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 1}, 
{"LB2", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 2}, 
{"FLVL", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 3}, 
{"BARO", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 4}, 
{"EGT3", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 5}, 
{"EGT4", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 6}, 
{"EGT5", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 7}, 
{"EGT6", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 8}, 
{"EGT7", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 0.01}, 
{"EGT8", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 1}, 
{"BRKP", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 2}, 
{"NOS1", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 3}, 
{"TRBS", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 4}, 
{"CLTP", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 5}, 
{"WGP", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 6}, 
{"IJS2", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 7}, 
{"IGNA", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 8}, 
{"WHSL", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 9}, 
{"WHDF", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 10}, 
{NULL, 0, 0, 0, 0, 0, NULL, false, 0, NULL, NULL, UT_ASIS, 0}};

DATAPOINT MegasquirtDemo[] = {
{"HIDE", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 1}, 
// {NULL, 0, 0, 0, 0, 0, NULL, false, 0, NULL, NULL, UT_ASIS, 0},  // Uncomment to truncate array for small set data transmission testing
{"ADV", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 2}, 
{"AFR", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 3}, 
{"BST", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 4}, 
{"IAT", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 5}, 
{"CLT", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 6}, 
{"TPS", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 7}, 
{"BAT", 0, 0, 15, 10, 14, "G", true, 1, "", "", UT_ASIS, 0.5}, 
{"IAC", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 9}, 
{"GEAR", 0, 0, 7, 0, 7, "G", true, 0, "", "", UT_ASIS, 0.01}, 
{"FCOR", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 1}, 
{"FPR", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 2}, 
{"CLTP", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 3}, 
{"OIL", 0, 0, 100, 25, 75, "G", true, 0, "", "", UT_PSI, 4}, 
{"OILT", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_FAHRENHEIT, 5}, 
{"EGT", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 6}, 
{"VSS", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 7}, 
{"WCOR", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 8}, 
{"E85", 0, 0, 300, 0, 300, "G", true, 0, "", "", UT_ASIS, 9}, 
{"SEN1", 0, 0, 5, 0, 5, "S", true, 0, "", "", UT_ASIS, 0.25}, 
{"SEN2", 0, 0, 5, 0, 5, "S", true, 0, "", "", UT_ASIS, 0.25}, 
{"SEN3", 0, 0, 5, 0, 5, "S", true, 0, "", "", UT_ASIS, 0.25}, 
{"SEN4", 0, 0, 5, 0, 5, "S", true, 0, "", "", UT_ASIS, 0.25}, 
{"SEN5", 0, 0, 5, 0, 5, "S", true, 0, "", "", UT_ASIS, 0.25}, 
{"SEN6", 0, 0, 5, 0, 5, "S", true, 0, "", "", UT_ASIS, 0.25}, 
{"SEN7", 0, 0, 5, 0, 5, "S", true, 0, "", "", UT_ASIS, 0.25}, 
{"SEN8", 0, 0, 5, 0, 5, "S", true, 0, "", "", UT_ASIS, 0.25}, 
{"SEN9", 0, 0, 5, 0, 5, "S", true, 0, "", "", UT_ASIS, 0.25}, 
{"SEN10", 0, 0, 5, 0, 5, "S", true, 0, "", "", UT_ASIS, 0.25}, 
{"SEN11", 0, 0, 5, 0, 5, "S", true, 0, "", "", UT_ASIS, 0.25}, 
{"SEN12", 0, 0, 5, 0, 5, "S", true, 0, "", "", UT_ASIS, 0.25}, 
{"SEN13", 0, 0, 5, 0, 5, "S", true, 0, "", "", UT_ASIS, 0.25}, 
{"SEN14", 0, 0, 5, 0, 5, "S", true, 0, "", "", UT_ASIS, 0.25}, 
{"SEN15", 0, 0, 5, 0, 5, "S", true, 0, "", "", UT_ASIS, 0.25}, 
{"SEN16", 0, 0, 5, 0, 5, "S", true, 0, "", "", UT_ASIS, 0.25}, 
{NULL, 0, 0, 0, 0, 0, NULL, false, 0, NULL, NULL, UT_ASIS, 0}};

DATAPOINT CommonDataDemo[] = { // This is a second array of common data points that may not be EFI-specific, like 'Speed'
{"SPEED", 0, 0, 200, 0, 180, "Speed", true, 0, "", "", UT_MPH, 10}, 
// {NULL, 0, 0, 0, 0, 0, NULL, false, 0, NULL, NULL, UT_ASIS, 0},  // Uncomment to truncate array for small set data transmission testing
{"FUEL", 0, 0, 20, 5, 20, "Fuel", true, 0, "", "", UT_ASIS, 1}, 
{"RPM", 0, 0, 14000, 0, 13000, "RPM", true, 0, "", "", UT_ASIS, 1000}, 
{"TIREFD", 0, 0, 45, 30, 38, "TIREFD", true, 0, "", "", UT_ASIS, 1}, 
{"TIREFP", 0, 0, 45, 30, 38, "TIREFP", true, 0, "", "", UT_ASIS, 1}, 
{"TIRERD", 0, 0, 45, 30, 38, "TIRERD", true, 0, "", "", UT_ASIS, 1}, 
{"TIRERP", 0, 0, 45, 30, 38, "TIRERP", true, 0, "", "", UT_ASIS, 1}, 
{"TIRE", 0, 0, 45, 30, 38, "TIRE", true, 0, "", "", UT_ASIS, 1}, 
{"TURNL", 0, 0, 10, 0, 5, "LeftTurn", true, 0, "", "", UT_ASIS, 1}, 
{"TURNR", 0, 0, 20, 0, 10, "RightTurn", true, 0, "", "", UT_ASIS, 1}, 
{"LIGHTS", 0, 0, 1, 0, 1, "Lights", true, 0, "", "", UT_ASIS, 1}, 
{"LIGHTSHI", 0, 0, 40, 0, 20, "HighBeam", true, 0, "", "", UT_ASIS, 1}, 
{"CLNTT",  0, 0, 100, 0, 100, "CLNTT", true, 0, "C", "H", UT_ASIS, 1}, // Coolant Temp
{"ODO",  0, 0, 9999999, 0, 9999999, "ODO", true, 0, "", "", UT_MPH, 10}, // MG: Issue 0000841: Implement an Odometer widget

//{"PITCH",  0, 0, 360, 0, 360, "PITCH", true, 0, "", "", 1, UT_ASIS}, 
//{"ROLL",   0, 0, 360, 0, 360, "ROLL",  true, 0, "", "", 1, UT_ASIS}, 

{NULL, 0, 0, 0, 0, 0, NULL, false, 0, NULL, NULL, UT_ASIS, 0}};


// curDataPoints is linked to a specific EFI, based on EFIDevice
DATAPOINT * curDataPoints = EFIDevice.equals("HOLLEYTERMX2") ? HolleyDemo : (EFIDevice.equals("HALTECH2") ? HalTech2Demo : MegasquirtDemo);

#if !defined(CONFIG_BT_ENABLED) || !defined(CONFIG_BLUEDROID_ENABLED)
#error Bluetooth is not enabled! Please run `make menuconfig` to and enable it
#endif

#if !defined(CONFIG_BT_SPP_ENABLED)
#error Serial Bluetooth not available or not enabled. It is only available for the ESP32 chip.
#endif

BluetoothSerial SerialBT;

// Define this to enable Serial message debugging
#define SERIALLOG 1

#ifdef SERIALLOG
static char debugBuffer[512];
void serialLog( const char* msg )
{
  Serial.println( msg );
}
#else
#define serialLog(x) /* serialLog(x) */
#endif

void setup() {
#ifdef SERIALLOG
  Serial.begin(115200);
  serialLog( "Started" );

  snprintf(debugBuffer, sizeof(debugBuffer)-1, "aetup: requestedUnitType[  1 ] = %d \n", 
      requestedUnitType[  1 ]);
    serialLog(debugBuffer);

#endif
  SerialBT.begin(device_name );  // Bluetooth device name
  serialLog( device_name.c_str() );
  //Serial.printf("The device with name \"%s\" is started.\nNow you can pair it with Bluetooth!\n", device_name.c_str());
#ifdef USE_PIN
  SerialBT.setPin(pin);
  //Serial.println("Using PIN");
#endif

  totalDatapointsGlobal = buildDatapoints();
  
  // Added by Alex:
  // Create tasks and assign them to cores
  xTaskCreatePinnedToCore(
    BluetoothTask,       // Task function
    "BluetoothTask",     // Name of the task
    4096,                // Stack size
    NULL,                // Task input parameter
    1,                   // Priority of the task
    &BluetoothTaskHandle,// Task handle
    1                    // Core to run the task on
  );

  xTaskCreatePinnedToCore(
    StringManipulationTask, // Task function
    "StringManipulationTask", // Name of the task
    4096,                  // Stack size
    NULL,                  // Task input parameter
    1,                     // Priority of the task
    &StringManipulationTaskHandle, // Task handle
    0                      // Core to run the task on
  );
} 

void refreshGauges3(const char *label, float curVal, float minVal, float maxVal) {
  DATAPOINT *ptrDatapoint;
  for (int i = 0; arpCombinedDataPoints[i] != NULL; i++) {
    ptrDatapoint = arpCombinedDataPoints[i];
    if (strcasecmp(ptrDatapoint->label, label) == 0) {
      ptrDatapoint->value = curVal;
      ptrDatapoint->min = (minVal != 0) ? minVal : ptrDatapoint->min;
      ptrDatapoint->max = (maxVal != 0) ? maxVal : ptrDatapoint->max;
      break;
    }
  }
}

void updateDatapoints() {
  float newVal = 0;
  DATAPOINT *ptrDatapoint;
  for (int i = 0; arpCombinedDataPoints[i] != NULL; i++) {
    ptrDatapoint = arpCombinedDataPoints[i];
    if (ptrDatapoint->included) {
      newVal = ptrDatapoint->value + ptrDatapoint->demo_dir;
      if (newVal < ptrDatapoint->min) {
        newVal = ptrDatapoint->min;
        ptrDatapoint->demo_dir = -ptrDatapoint->demo_dir;
      } else if (newVal > ptrDatapoint->max) {
        newVal = ptrDatapoint->max;
        ptrDatapoint->demo_dir = -ptrDatapoint->demo_dir;
      }
      refreshGauges3(ptrDatapoint->label, newVal, ptrDatapoint->min, ptrDatapoint->max);
    }
  }
}

void setInclude(const char *label) {
  for (int i = 0; arpCombinedDataPoints[i] != NULL; i++) {
    if (strcasecmp(arpCombinedDataPoints[i]->label, label) == 0) {
      arpCombinedDataPoints[i]->included = true;
      break;
    }
  }
}

void clearAllIncludes() {
  for (int i = 0; arpCombinedDataPoints[i] != NULL; i++) {
    arpCombinedDataPoints[i]->included = false;
  }
}

int buildDatapoints() {
  int combined = 0, max = MAXDATAPOINTS - 1;
  if (curDataPoints != NULL) {
    for (int i = 0; curDataPoints[i].label != NULL && combined < max; i++)
      arpCombinedDataPoints[combined++] = &curDataPoints[i];
  }
  for (int i = 0; CommonDataDemo[i].label != NULL && combined < max; i++) {
    arpCombinedDataPoints[combined++] = &CommonDataDemo[i];
  }
  arpCombinedDataPoints[combined + 1] = NULL;
  return combined;
}

void buildBuffer(int totalDatapoints, bool forProvided) {
  memset(buffer, 0, sizeof(buffer));
  if (forProvided)
  {
    strcpy(buffer, "<<PROVIDED:\nVersion:" APPVERSION " \n"); // Begin data block, with version
  }
  else
    strcpy(buffer, "<<"); // Begin data block
  bufferOffset = strlen(buffer);
  buildBufferEx(totalDatapoints, forProvided);
    
  bufferOffset = strlen(buffer);
  bufferOffset += snprintf(buffer + bufferOffset, sizeof(buffer) - bufferOffset, ">>");
  if (forProvided) {
    serialLog( "Done buildBuffer");
  }
}

// Builds datapoints as a string into buffer, but breaks datapoints into groups of maxDatapointsToSend
void buildBufferEx(int totalDatapoints, bool includeAll) {
  static int toSkipDatapoint = 0;
  static int lastDatapointInBuffer = 0;
  int skipDatapoint = 0;
  int addedToBufferSoFar = 0;
  const char *format;
  DATAPOINT *ptrDatapoint;

  for (int i = 0; arpCombinedDataPoints[i] != NULL; i++) {
    ptrDatapoint = arpCombinedDataPoints[i];
    if (ptrDatapoint->included || includeAll) {
      if (!includeAll && maxDatapointsToSend > 0) {
        if (skipDatapoint < toSkipDatapoint) {
          skipDatapoint++;
          continue;
        }
        if (addedToBufferSoFar >= maxDatapointsToSend) {
          addedToBufferSoFar = 0;
          toSkipDatapoint = lastDatapointInBuffer;
          break;
        }
        addedToBufferSoFar++;
        lastDatapointInBuffer++;
        if (lastDatapointInBuffer >= totalDatapoints) {
          lastDatapointInBuffer = 0;
          toSkipDatapoint = 0;
          skipDatapoint = 0;
        }
      }
      
      // MG: Issue	0000836: Implement Data Format feature
      if( ptrDatapoint->unitType != UT_ASIS && requestedUnitType[  ptrDatapoint->unitType ] != ptrDatapoint->unitType) { // MG: Implement conversions utilizing Data Format settings
        ptrDatapoint = convertUnitType( ptrDatapoint,requestedUnitType[  ptrDatapoint->unitType ] );
      } 

      // If ok, add datapoint to buffer
      if (ptrDatapoint->decimals == 0)
        format = includeAll ? "%s,%.0f,%.0f,%.0f,%.0f,%.0f,%s,%s,%s,%s,%d,%d,%f\n" : "%s,%.0f,%.0f,%.0f,%.0f,%.0f,%s\n";
      else if (ptrDatapoint->decimals == 1)
        format = includeAll ? "%s,%.1f,%.1f,%.1f,%.1f,%.1f,%s,%s,%s,%s,%d,%d,%.1f\n" : "%s,%.1f,%.1f,%.1f,%.1f,%.1f,%s\n";
      else
        format = includeAll ? "%s,%f,%f,%f,%f,%f,%s,%s,%s,%s,%d,%d,%f\n" : "%s,%f,%f,%f,%f,%f,%s\n";
      if( strcmp( ptrDatapoint->label, "Speed" ) == 0 )
      {
        serialLog(unitTypeString[ ptrDatapoint->unitType  ]);
      }
      bufferOffset += snprintf(buffer + bufferOffset, sizeof(buffer) - bufferOffset, format, 
        ptrDatapoint->label, 
        ptrDatapoint->value,
        ptrDatapoint->min, 
        ptrDatapoint->max,
        ptrDatapoint->warnlow, 
        ptrDatapoint->warnhigh,
        ptrDatapoint->type,
        ptrDatapoint->startCaption, 
        ptrDatapoint->endCaption,
        unitTypeString[ ptrDatapoint->unitType  ],
        // These are included only if includeAll is true
        ptrDatapoint->included ? 1 : 0, 
        ptrDatapoint->decimals, 
        ptrDatapoint->demo_dir);

    }
  }
}

void sendBuffer() {
  #define MAXSENDS 10000
  int sends = 0;
  if (curDataPoints != NULL) {
    if (SerialBT.connected()) {
      int sent = 0, toSend = bufferOffset;
      while (toSend > 0 && sends < MAXSENDS) {
        sent = SerialBT.write((const uint8_t *)buffer + sent, bufferOffset - sent);
        SerialBT.flush();
        delay(1); // Optional
        toSend -= sent;
        sends++;
      }
    }
  }
}

// workaround from https://issuetracker.google.com/issues/36990183 demonstrated
// the SerialBT.readString() was taking a second to read a string.
// After reviewing the Stream.cpp source code, I recreated my own readString:
String myReadString() {
  String ret;
  int c;
  while (SerialBT.available()) {
    c = SerialBT.read();
    if (c >= 0)
      ret += (char)c;
  }
  return ret;
}

void clearAllSettings() {
  for( int i = 0; i <  MAXSETTINGS; i++  )
  {
    if( settings[i].value != NULL ) 
    {
      free( settings[i].value );
      settings[i].value = NULL;
    }

    if( settings[i].key != NULL )
    {
      free( settings[i].key );
      settings[i].key = NULL;
    }
  }
}

// MG: Issue	0000836: Implement Data Format feature (data conversion example on ESP32 side) 
DATAPOINT* convertUnitType( DATAPOINT* ptrDatapoint, UnitType target)
{
  static DATAPOINT myDataPoint;
#ifdef SERIALLOG
  static uint nextCall = xTaskGetTickCount();
  
  uint thisCall = xTaskGetTickCount();
  if( thisCall > nextCall && strcmp( ptrDatapoint->label, "SPEED") == 0 )
  {
    snprintf(debugBuffer, sizeof(debugBuffer), "SPEED: convertUnitType %u ptrDatapoint->unitType=%d requestedUnitType[  ptrDatapoint->unitType ] = %d \n", thisCall, 
      ptrDatapoint->unitType, requestedUnitType[  ptrDatapoint->unitType ]);
    serialLog(debugBuffer);
    nextCall =  thisCall + pdMS_TO_TICKS(1000);
  }
#endif
  myDataPoint.label = ptrDatapoint->label;
  myDataPoint.type = ptrDatapoint->type;
  myDataPoint.included = ptrDatapoint->included;
  myDataPoint.decimals = ptrDatapoint->decimals;
  myDataPoint.startCaption = ptrDatapoint->startCaption;
  myDataPoint.endCaption = ptrDatapoint->endCaption;
  myDataPoint.unitType = target; // MG: Issue	0000836: Implement Data Format feature

  // Data below is for creating demo values
  float demo_dir;
  if( ptrDatapoint->unitType == UT_MPH && requestedUnitType[  ptrDatapoint->unitType ] == UT_KPH )
  { // KPH = MPH * 1.60934
    myDataPoint.value = ptrDatapoint->value * 1.60934;
    myDataPoint.min = ptrDatapoint->min * 1.60934;
    myDataPoint.max = ptrDatapoint->max * 1.60934;
    myDataPoint.warnhigh = ptrDatapoint->warnhigh * 1.60934;
    myDataPoint.warnlow = ptrDatapoint->warnlow * 1.60934;
  } else if( ptrDatapoint->unitType == UT_KPH && requestedUnitType[  ptrDatapoint->unitType ] == UT_MPH ) 
  { // MPH = KPH / 1.60934
    myDataPoint.value = ptrDatapoint->value / 1.60934;
    myDataPoint.min = ptrDatapoint->min / 1.60934;
    myDataPoint.max = ptrDatapoint->max / 1.60934;
    myDataPoint.warnhigh = ptrDatapoint->warnhigh / 1.60934;
    myDataPoint.warnlow = ptrDatapoint->warnlow / 1.60934;

  } else if( ptrDatapoint->unitType == UT_FAHRENHEIT && requestedUnitType[  ptrDatapoint->unitType ] == UT_CELSIUS )
  { //C = (F - 32) × 5 / 9
    myDataPoint.value = (ptrDatapoint->value-32) * 5 / 9;
    myDataPoint.min = (ptrDatapoint->min-32) * 5 / 9;
    myDataPoint.max = (ptrDatapoint->max-32) * 5 / 9;
    myDataPoint.warnhigh = (ptrDatapoint->warnhigh-32) * 5 / 9;
    myDataPoint.warnlow = (ptrDatapoint->warnlow-32) * 5 / 9;
  } else if( ptrDatapoint->unitType == UT_CELSIUS && requestedUnitType[  ptrDatapoint->unitType ] == UT_FAHRENHEIT ) {
    //F = (C × 9 / 5) + 32
    myDataPoint.value = (ptrDatapoint->value * 9 / 5) + 32;
    myDataPoint.min = (ptrDatapoint->min * 9 / 5) + 32;
    myDataPoint.max = (ptrDatapoint->max * 9 / 5) + 32;
    myDataPoint.warnhigh = (ptrDatapoint->warnhigh * 9 / 5) + 32;
    myDataPoint.warnlow = (ptrDatapoint->warnlow * 9 / 5) + 32;
  
  } else if( ptrDatapoint->unitType == UT_PSI && requestedUnitType[  ptrDatapoint->unitType ] == UT_KPA )
  { // kPa = PSI × 6.89476
    myDataPoint.value = ptrDatapoint->value * 6.89476;
    myDataPoint.min = ptrDatapoint->min * 6.89476;
    myDataPoint.max = ptrDatapoint->max * 6.89476;
    myDataPoint.warnhigh = ptrDatapoint->warnhigh * 6.89476;
    myDataPoint.warnlow = ptrDatapoint->warnlow * 6.89476;
  } else if( ptrDatapoint->unitType == UT_KPA && requestedUnitType[  ptrDatapoint->unitType ] == UT_PSI ) {
    // PSI = kPa / 6.89476
    myDataPoint.value = ptrDatapoint->value / 6.89476;
    myDataPoint.min = ptrDatapoint->min / 6.89476;
    myDataPoint.max = ptrDatapoint->max / 6.89476;
    myDataPoint.warnhigh = ptrDatapoint->warnhigh / 6.89476;
    myDataPoint.warnlow = ptrDatapoint->warnlow / 6.89476;

  } else if( ptrDatapoint->unitType == UT_AFR && requestedUnitType[  ptrDatapoint->unitType ] == UT_LAMBDA )
  { // TODO: Implement conversion formula
    bool doBaroCalc = requestedUnitType[  UT_BAROCALC ] == UT_BAROCALC; // If user wants BaroCalc, now doBaroCalc is true
    myDataPoint.value = ptrDatapoint->value;
    myDataPoint.min = ptrDatapoint->min;
    myDataPoint.max = ptrDatapoint->max;
    myDataPoint.warnhigh = ptrDatapoint->warnhigh;
    myDataPoint.warnlow = ptrDatapoint->warnlow;
  } else if( ptrDatapoint->unitType == UT_LAMBDA && requestedUnitType[  ptrDatapoint->unitType ] == UT_AFR ) {
    // TODO: Implement conversion formula
    bool doBaroCalc = requestedUnitType[  UT_BAROCALC ] == UT_BAROCALC; // If user wants BaroCalc, now doBaroCalc is true
    myDataPoint.value = ptrDatapoint->value;
    myDataPoint.min = ptrDatapoint->min;
    myDataPoint.max = ptrDatapoint->max;
    myDataPoint.warnhigh = ptrDatapoint->warnhigh;
    myDataPoint.warnlow = ptrDatapoint->warnlow;
  }
  else { // We shouldn't get here, unless there is some undefined unit type, which is very bad.  Try not to die
  // Just return what we got
    myDataPoint.value = ptrDatapoint->value;
    myDataPoint.min = ptrDatapoint->min;
    myDataPoint.max = ptrDatapoint->max;
    myDataPoint.warnhigh = ptrDatapoint->warnhigh;
    myDataPoint.warnlow = ptrDatapoint->warnlow;
  }
  return &myDataPoint;
} 

// MG: Issue	0000836: Implement Data Format feature
void setSetting( String key, String value ) { // Convert mutable block from "key:value\n" to "key" and "value", then store
  if( key.equalsIgnoreCase( "Speed" ) ) {
    if( value.equalsIgnoreCase("MPH") ) {
      requestedUnitType[ UT_MPH ] = UT_MPH;
      requestedUnitType[ UT_KPH ] = UT_MPH;
    } else {
      requestedUnitType[ UT_MPH ] = UT_KPH;
      requestedUnitType[ UT_KPH ] = UT_KPH;
    }
  } else if( key.equalsIgnoreCase( "Temperature") ) {
    if( value.equalsIgnoreCase("Fahrenheit") ) {
      requestedUnitType[ UT_FAHRENHEIT ] = UT_FAHRENHEIT;
      requestedUnitType[ UT_CELSIUS ] = UT_FAHRENHEIT;
    } else {
      requestedUnitType[ UT_FAHRENHEIT ] = UT_CELSIUS;
      requestedUnitType[ UT_CELSIUS ] = UT_CELSIUS;
    }
  } else if( key.equalsIgnoreCase( "Pressure") ) {
    if( value.equalsIgnoreCase("PSI") ) {
      requestedUnitType[ UT_PSI ] = UT_PSI;
      requestedUnitType[ UT_KPA ] = UT_PSI;
    } else {
      requestedUnitType[ UT_PSI ] = UT_KPA;
      requestedUnitType[ UT_KPA ] = UT_KPA;
    }
  } else if( key.equalsIgnoreCase( "Fuel") ) {
    if( value.equalsIgnoreCase("AFR") ) {
      requestedUnitType[ UT_AFR ] = UT_AFR;
      requestedUnitType[ UT_LAMBDA ] = UT_AFR;
    } else {
      requestedUnitType[ UT_AFR ] = UT_LAMBDA;
      requestedUnitType[ UT_LAMBDA ] = UT_LAMBDA;
    }
  } else if( key.equalsIgnoreCase( "BaroCalc") ) {
    requestedUnitType[ UT_BAROCALC ] = value.equalsIgnoreCase("Y")  ? UT_BAROCALC : UT_ASIS;
  }
}

void processCommands(int totalDatapoints) {
  while (SerialBT.available()) {
    received.concat(myReadString());
    int start = received.indexOf("<<");
    int stop = received.indexOf(">>");
    while (start > -1 && stop > -1) {
      if (stop < start)
        received.remove(0, start);
      else {
        String block = received.substring(start + 2, stop);
        received.remove(0, stop + 2);
        
        // block is now a single command
        if (block.compareTo("IDENTIFY") == 0) {
          buildBuffer(totalDatapoints, true);
          sendBuffer();
          serialLog( "Received identify" );
        
        } else if (block.indexOf("ACCEPTED:") == 0) {
          block.replace("ACCEPTED:", "");
          String label = "";
          serialLog( "Received accepted" );
          clearAllIncludes();
          for (int start = 0, end = block.length(); start < end; start++) {
            if (block.charAt(start) == ',') {
              setInclude(label.c_str());
              label = "";
            } else {
              label += block.charAt(start);
            }
          }
          if (!label.isEmpty())
            setInclude(label.c_str());

        } else if (block.indexOf("SETTINGS:") == 0) {
          // MG: Issue	0000836: Implement Data Format feature
          // Settings must  be in the format "key1:value1\nkey2:value2\n...keyn:valuen\n"
          block.replace("SETTINGS:", "");
          serialLog( "Settings accepted" );

          for (int start = 0, index = 0, end = block.length(), sep=-1; start < end; index++) {
            if (block.charAt(index) == ':') {
              sep = index;
            }
            if (block.charAt(index) == '\n') {
              if( sep != -1 )
                setSetting( block.substring( start, sep ), block.substring( sep+1, index ));
              start = index + 1;
              sep = -1;
            }
          }
          buildBuffer(totalDatapoints, true);
          sendBuffer();
        } // else if (block.indexOf("SETTINGS:") == 0)
        
      }
      start = received.indexOf("<<");
      stop = received.indexOf(">>");
    }
  }
}

void BluetoothTask(void *pvParameters) {
  while (true) {
    sendDataBuffer( totalDatapointsGlobal );
    processCommands( totalDatapointsGlobal );
    vTaskDelay(pdMS_TO_TICKS(REFRESH_INTERVAL_MS*2));
  }
}

void StringManipulationTask(void *pvParameters) {
  while (true) {
    updateDatapoints();
    vTaskDelay(pdMS_TO_TICKS(REFRESH_INTERVAL_MS));
  }
}

void sendDataBuffer(int totalDatapoints) {
  buildBuffer(totalDatapoints, false);
  sendBuffer();
}

void loop() {
  // Do nothing, since Alex implemented the xTaskCreatePinnedToCore calls.
  // Note: MG can not guarantee that BluetoothTask and StringManipulationTask tasks don't have a conflict simultaneously accessing data.
}
