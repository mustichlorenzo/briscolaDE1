package application;

import java.io.IOException;
import java.io.InputStream;
//import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.PrintStream;
import gnu.io.CommPortIdentifier;
import gnu.io.PortInUseException;
import gnu.io.SerialPort;
import gnu.io.SerialPortEvent; 
import gnu.io.SerialPortEventListener;

import java.util.ArrayList;
import java.util.Enumeration;

public class SerialAdapter implements SerialPortEventListener {

	InputParser parser;

	SerialPort serialPort;
	/** The port we're normally going to use. */
	private static final String PORT_NAMES[] = { 
			"/dev/tty.usbserial-A9007UX1", // Mac OS X
			"/dev/ttyACM0", "/dev/serial/by-id/usb-Arduino__www.arduino.cc__0043_85430343238351600220-if00\n",
			"/dev/ttyACM1", "/dev/ttyACM2",// Raspberry Pi
			"/dev/ttyUSB0", // Linux
			"COM4", "COM3", "COM5", "COM6", "COM7", "COM8", "COM9", "COM10" // Windows
	};
	/**
	 * A BufferedReader which will be fed by a InputStreamReader 
	 * converting the bytes into characters 
	 * making the displayed results codepage independent
	 */
//	private BufferedReader input;
	private InputStream is;
	private byte[] readBuffer = new byte[8192];
	/** The output stream to the port */
	private OutputStream output;
	private PrintStream os;
	/** Milliseconds to block while waiting for port open */
	private static final int TIME_OUT = 2000;
	/** Default bits per second for COM port. */
	 private static final int DATA_RATE = 9600;
//	 private static final int DATA_RATE = 115200;


	public SerialAdapter(InputParser parser) throws PortInUseException {
		this.parser = parser;
		// the next line is for Raspberry Pi and 
		// gets us into the while loop and was suggested here was suggested http://www.raspberrypi.org/phpBB3/viewtopic.php?f=81&t=32186
		//System.setProperty("gnu.io.rxtx.SerialPorts", "COM3");

		CommPortIdentifier portId = null;
		@SuppressWarnings("rawtypes")
		Enumeration portEnum = CommPortIdentifier.getPortIdentifiers();

		//First, Find an instance of serial port as set in PORT_NAMES.
		while (portEnum.hasMoreElements()) {
			CommPortIdentifier currPortId = (CommPortIdentifier) portEnum.nextElement();
			for (String portName : PORT_NAMES) {
				if (currPortId.getName().equals(portName)) {
					portId = currPortId;
					break;
				}
			}
		}
		if (portId == null) {
			System.out.println("Could not find COM port.");
			return;
		}

		try {
			// open serial port, and use class name for the appName.
			serialPort = (SerialPort) portId.open(this.getClass().getName(),
					TIME_OUT);

			// set port parameters
			serialPort.setSerialPortParams(DATA_RATE,
					SerialPort.DATABITS_8,
					SerialPort.STOPBITS_1,
					SerialPort.PARITY_NONE);

			// open the streams
			// input = new BufferedReader(new InputStreamReader(serialPort.getInputStream()));
			is = serialPort.getInputStream();
			output = serialPort.getOutputStream();
			os = new PrintStream(output, true);
			// add event listeners
			serialPort.addEventListener(this);
			serialPort.notifyOnDataAvailable(true);
		} catch (PortInUseException e) {
			throw new PortInUseException();
		} catch (Exception e) {
			System.err.println(e.toString());
		}
	}


	/**
	 * This should be called when you stop using the port.
	 * This will prevent port locking on platforms like Linux.
	 */
	public synchronized void close() {
		if (serialPort != null) {
			serialPort.removeEventListener();
			serialPort.close();
		}
	}
	
	private void readSerial() {
	    try {
	        int availableBytes = is.available();
	        if (availableBytes > 0) {
	            // Read the serial port
	            is.read(readBuffer, 0, availableBytes);
	        }
	        if(availableBytes == 2) {
	        	for(int i = availableBytes-1; i >= 0; i--) {
		        	parser.parseFrame(readBuffer[i]);
		        }
	        } else {
		        for(int i = 0; i < availableBytes; i++) {
		        	parser.parseFrame(readBuffer[i]);
		        }
	        }
	    } catch (IOException e) {
	    }
	}

	/**
	 * Versione modificata
	 */
	public synchronized void serialEvent(SerialPortEvent oEvent) {
		if (oEvent.getEventType() == SerialPortEvent.DATA_AVAILABLE) {
			try {
			//	byte buffer;
				// System.out.print("Ricev: ");
				// System.out.print(Integer.toBinaryString(buffer));
				// System.out.println();
				
				readSerial();
			} catch (Exception e) {
				System.err.println(e.toString());
			}
		}
		// Ignore all the other eventTypes, but you should consider the other ones.
	}

	public void listen() {
		Thread t=new Thread() {
			public void run() {
				//the following line will keep this app alive for 1000 seconds,
				//waiting for events to occur and responding to them (printing incoming messages to console).
				try { while (true) Thread.sleep(1000000); } catch (InterruptedException ie) {}
			}
		};
		t.start();
		System.out.println("Started");
	}

	public void writeToSerialPort(byte out) {
		System.out.print("\nInvio: ");
		if(Integer.toBinaryString(out).length()<=8)
			System.out.println(Integer.toBinaryString(out));
		else 
			System.out.print(Integer.toBinaryString(out).substring(24));
		os.write(out);
	}


	public void sendMano(ArrayList<Carta> mano) {
		for(Carta c: mano) {
			this.writeToSerialPort(this.parser.fromCartaToByte(c));
			System.out.print(" --> " + c.toString());
			try {
				Thread.sleep(500);
			} catch (InterruptedException e) {
				e.printStackTrace();
			}
		}
		
	}


	public void sendBriscola(Carta briscola) {
		this.writeToSerialPort(this.parser.fromCartaToByte(briscola));
		System.out.print(" --> " + briscola.toString() + " [BRISCOLA]");
		System.out.println();
		try {
			Thread.sleep(500);
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
	}


	public void sendNextCard(Carta nextCard) {
		this.writeToSerialPort(this.parser.fromCartaToByte(nextCard));
		System.out.print(" --> " + nextCard.toString());
		System.out.println();
		try {
			Thread.sleep(500);
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
	}


}
