/**
 *  GODPAPER Confidential,Copyright 2012. All rights reserved.
 *
 *  Permission is hereby granted, free of charge, to any person obtaining
 *  a copy of this software and associated documentation files (the "Software"),
 *  to deal in the Software without restriction, including without limitation
 *  the rights to use, copy, modify, merge, publish, distribute, sub-license,
 *  and/or sell copies of the Software, and to permit persons to whom the
 *  Software is furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included
 *  in all copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 *  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 *  THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 *  IN THE SOFTWARE.
 */
package
{
	//--------------------------------------------------------------------------
	//
	//  Imports
	//
	//--------------------------------------------------------------------------
	import com.godpaper.mqtt.as3.utils.UIDUtil;

	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.Socket;
	import flash.system.Security;
	import flash.utils.ByteArray;

	/**
	 * Pure Action Script 3 that implements the MQTT (Message Queue Telemetry Transport) protocol, a lightweight protocol for publish/subscribe messaging. </br>
	 * AS3 socket is a mechanism used to send data over a network (e.g. the Internet), it is the combination of an IP address and a port. </br>
	 * @see http://public.dhe.ibm.com/software/dw/webservices/ws-mqtt/mqtt-v3r1.html
	 * @see http://public.dhe.ibm.com/software/dw/webservices/ws-mqtt/MQTT_V3.1_Protocol_Specific.pdf
	 * @see http://mosquitto.org/download/
	 * @see https://www.ibm.com/developerworks/mydeveloperworks/blogs/messaging/entry/write_your_own_mqtt_client_without_using_any_api_in_minutes1?lang=en
	 *
	 * @author yangboz
	 * @langVersion 3.0
	 * @playerVersion 11.2+
	 * @airVersion 3.2+
	 * Created Nov 20, 2012 10:19:53 AM
	 */
	public class MQTTClient_AS3 extends Sprite
	{
		//--------------------------------------------------------------------------
		//
		//  Variables
		//
		//--------------------------------------------------------------------------
		private var mqttSocket:Socket;
		//First let's construct the MQTT messages that need to be sent:
		private var connectMesage:ByteArray=new ByteArray();
		private var publishMessage:ByteArray=new ByteArray();
		private var subscribeMessage:ByteArray=new ByteArray();
		private var disconnectMessage:ByteArray=new ByteArray();
		//----------------------------------
		//  CONSTANTS
		//----------------------------------
		//Notice: You need to define a cross domain policy file at your remote server root document, or have a policy file server on the target. 
		private static const MY_HOST:String="16.157.65.23"; //You'd better change it to your private ip address! //test.mosquitto.org//16.157.65.23(Ubuntu)//15.185.106.72(hp cs instance)
		private static const MY_PORT:Number=1883; //Socket port.

		//--------------------------------------------------------------------------
		//
		//  Public properties
		//
		//-------------------------------------------------------------------------- 

		//--------------------------------------------------------------------------
		//
		//  Protected properties
		//
		//-------------------------------------------------------------------------- 

		//--------------------------------------------------------------------------
		//
		//  Constructor
		//
		//--------------------------------------------------------------------------
		public function MQTTClient_AS3()
		{
//			Creating a Socket
			this.mqttSocket=new Socket();
			//Notice: You need to define a cross domain policy file at your remote server root document, or have a policy file server on the target. 
			Security.allowDomain("*");
//			Security.loadPolicyFile("http://www.lookbackon.com/crossdomain.xml");  
			//
			mqttSocket.addEventListener(Event.CONNECT, onConnect); //dispatched when the connection is established
			mqttSocket.addEventListener(Event.CLOSE, onClose); //dispatched when the connection is closed
			mqttSocket.addEventListener(IOErrorEvent.IO_ERROR, onError); //dispatched when an error occurs
			mqttSocket.addEventListener(ProgressEvent.SOCKET_DATA, onSocketData); //dispatched when socket can be read
			mqttSocket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecError); //dispatched when security gets in the way
			//
			mqttSocket.connect(MY_HOST, MY_PORT);
			//MQTT byte array prepare.
			//@see https://www.ibm.com/developerworks/mydeveloperworks/blogs/messaging/entry/write_your_own_mqtt_client_without_using_any_api_in_minutes1?lang=en
			//for connection
			this.connectMesage.writeByte(0x10); //Connect
			this.connectMesage.writeByte(0x0C + 0x04); //Remaining Length
			this.connectMesage.writeByte(0x00); //0
			this.connectMesage.writeByte(0x06); //6
			this.connectMesage.writeByte(0x4d); //M
			this.connectMesage.writeByte(0x51); //Q
			this.connectMesage.writeByte(0x49); //I
			this.connectMesage.writeByte(0x73); //S
			this.connectMesage.writeByte(0x64); //D
			this.connectMesage.writeByte(0x70); //P
			this.connectMesage.writeByte(0x03); //Protocol version = 3
			this.connectMesage.writeByte(0x02); //Clean session only
			this.connectMesage.writeByte(0x00); //Keepalive MSB
			this.connectMesage.writeByte(0x3c); //Keepaliave LSB = 60
			this.connectMesage.writeByte(0x00); //String length MSB
			this.connectMesage.writeByte(0x02); //String length LSB = 2
			this.connectMesage.writeByte(0x4d); //M
			this.connectMesage.writeByte(0x70); //P .. Let's say client ID = MP
			//for subscribe: subscribes to topics */
			
			//for publish
			this.publishMessage.writeByte(0x30); //Publish with QOS 0
			this.publishMessage.writeByte(0x05 + 0x05); //Remaining length
			this.publishMessage.writeByte(0x00); //MSB
			this.publishMessage.writeByte(0x03); //3 bytes of topic
			this.publishMessage.writeByte(0x61); //a
			this.publishMessage.writeByte(0x2F); ///
			this.publishMessage.writeByte(0x62); //b (a/b) is the topic
			this.publishMessage.writeUTFBytes("HELLO"); // (0x48, 0x45 , 0x4c , 0x4c, 0x4f); //HELLO is the message
			//for disconnect
			this.disconnectMessage.writeByte(0x0E); //Disconnect
			this.disconnectMessage.writeByte(0x00); //Disconnect
			
		}

		//--------------------------------------------------------------------------
		//
		//  Public methods
		//
		//--------------------------------------------------------------------------

		//--------------------------------------------------------------------------
		//
		//  Protected methods
		//
		//--------------------------------------------------------------------------

		//--------------------------------------------------------------------------
		//
		//  Private methods
		//
		//--------------------------------------------------------------------------
		private function onConnect(event:Event):void
		{
			trace(event);
//			mqttSocket.writeUTFBytes("GET / HTTP/1.1\n");
//			mqttSocket.writeUTFBytes("Host: hejp.co.uk\n");
//			mqttSocket.writeUTFBytes("\n");
			trace("connectMesage.length:",this.connectMesage.length);
			this.mqttSocket.writeBytes(this.connectMesage,0,this.connectMesage.length);
//			trace(this.mqttSocket.endian);
			this.mqttSocket.flush();
		}

		private function onClose(event:Event):void
		{
			// Security error is thrown if this line is excluded
  			trace(event);
			mqttSocket.writeBytes(this.disconnectMessage,0,this.disconnectMessage.length);
			mqttSocket.close();
		}

		private function onError(event:IOErrorEvent):void
		{
			trace("IO Error: " + event);
		}

		private function onSecError(event:SecurityErrorEvent):void
		{
			trace("Security Error: " + event);
		}

		private function onSocketData(event:ProgressEvent):void
		{
			trace( "Socket received " + this.mqttSocket.bytesAvailable + " byte(s) of data:");  
			// Loop over all of the received data, and only read a byte if there  is one available 
			while  (mqttSocket.bytesAvailable)
			{
				// Read a byte from the socket and display it  
				var data:int = mqttSocket.readByte();  
				trace( data );  
//				trace(mqttSocket.readUTFBytes(mqttSocket.bytesAvailable).toString());
			}
			//publish message for testing
//			this.mqttSocket.writeBytes(this.publishMessage,0,this.publishMessage.length);
//			this.mqttSocket.flush();
		}

		// 
		private function generateClientID():String
		{
			var uuid:String=UIDUtil.createUID();
			return uuid;
		}

	}

}
