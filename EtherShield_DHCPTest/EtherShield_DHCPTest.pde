/*
 * Arduino ENC28J60 Ethernet shield DHCP client test
 */

#include <EtherShield.h>

// Note: This software implements a web server and a web browser.
// The web server is at "myip" 
// 
// Please modify the following lines. mac and ip have to be unique
// in your local area network. You can not have the same numbers in
// two devices:
// how did I get the mac addr? Translate the first 5 numbers into ASCII gives "NANOD"
// then use your ID as the last number for uniqueness.
static uint8_t mymac[6] = { 0x4e,0x40,0x4e,0x4f,0x44,0x00 };

// IP Address and netmask returned by DHCP
static uint8_t myip[4] = { 0,0,0,0 };
static uint8_t mynetmask[4] = { 0,0,0,0 };

// IP address of the host being queried to contact (IP of the first portion of the URL):
static uint8_t websrvip[4] = { 0, 0, 0, 0 };

// Default Gateway, DNS server and DHCP Server addresses.
// Populated as part of DHCP address allocation
static uint8_t gwip[4] = { 0,0,0,0 };
static uint8_t dnsip[4] = { 0,0,0,0 };
static uint8_t dhcpsvrip[4] = { 0,0,0,0 };

#define DHCPLED 6

// listen port for tcp/www:
#define MYWWWPORT 80

#define BUFFER_SIZE 750
static uint8_t buf[BUFFER_SIZE+1];

EtherShield es=EtherShield();

void setup(){
  Serial.begin(19200);
  Serial.println("DHCP Client test");
  pinMode( DHCPLED, OUTPUT);
  digitalWrite( DHCPLED, LOW);
  pinMode( 8, OUTPUT);
  digitalWrite( 8, LOW);

  for( int i=0; i<6; i++ ) {
    Serial.print( mymac[i], HEX );
    Serial.print( i < 5 ? ":" : "" );
  }
  Serial.println();
  
  // initialize enc28j60
  es.ES_enc28j60SpiInit();

  Serial.println("Init ENC28J60");
  es.ES_enc28j60Init(mymac, 8);

  Serial.println("Init done");
  
  Serial.print( "ENC28J60 version " );
  Serial.println( es.ES_enc28j60Revision(), HEX);
  if( es.ES_enc28j60Revision() <= 0 ) 
    Serial.println( "Failed to access ENC28J60");
}

// Output a ip address from buffer from startByte
void printIP( uint8_t *buf ) {
  for( int i = 0; i < 4; i++ ) {
    Serial.print( buf[i], DEC );
    if( i<3 )
      Serial.print( "." );
  }
}

void loop(){
  uint16_t dat_p;
  long lastDhcpRequest = millis();
  uint8_t dhcpState = 0;
  boolean gotIp = false;

  Serial.println("Sending initial DHCP Discover");
  es.ES_dhcp_start( buf, mymac, myip, mynetmask,gwip, dnsip, dhcpsvrip );

  while(1) {
    // handle ping and wait for a tcp packet
    int plen = es.ES_enc28j60PacketReceive(BUFFER_SIZE, buf);

    dat_p=es.ES_packetloop_icmp_tcp(buf,plen);
    //    dat_p=es.ES_packetloop_icmp_tcp(buf,es.ES_enc28j60PacketReceive(BUFFER_SIZE, buf));
    if(dat_p==0) {
      int retstat = es.ES_check_for_dhcp_answer( buf, plen);
      dhcpState = es.ES_dhcp_state();
      // we are idle here
      if( dhcpState != DHCP_STATE_OK && !gotIp ) {
        if (millis() > (lastDhcpRequest + 10000L) ){
          lastDhcpRequest = millis();
    	  // send dhcp
          Serial.println("Sending DHCP Discover");
          es.ES_dhcp_start( buf, mymac, myip, mynetmask,gwip, dnsip, dhcpsvrip );
  	}
      } else {
        if( !gotIp ) {
          // Display the results:
           Serial.print( "My IP: " );
           printIP( myip );
           Serial.println();
        
           Serial.print( "Netmask: " );
           printIP( mynetmask );
           Serial.println();

           Serial.print( "DNS IP: " );
           printIP( dnsip );
           Serial.println();
           
           Serial.print( "GW IP: " );
           printIP( gwip );
           Serial.println();
           
           gotIp = true;
           digitalWrite( DHCPLED, HIGH);
        }
      }
    }
  }
}

