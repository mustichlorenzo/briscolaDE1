package application;

import java.math.BigInteger;

public class InputParser {
	private ReceiveCartaEventListener listener;
	private GameTracker gameTracker;
	
	public InputParser() {
		super();
	}
		
	public void setGameTracker(GameTracker gameTracker) {
		this.gameTracker = gameTracker;
	}

	public void setEventListener(ReceiveCartaEventListener listener) {
		this.listener = listener;
	}
	
	public void parseFrame(byte frame) {
		if(frame != 0x0) {
			Carta c = new Carta();
			if(((int) frame) < -40 || ((int) frame) > 0) {
				byte app = frame;
				byte typeFrame = (byte) ((app >>> 7) & 0x00000001) ;	//shift a dx (con riempimento di zeri) di 7 bit per ricavare il tipo del frame
				app = frame;
				if(typeFrame == 0x1) {						//verifico che il frame ricevuto sia una carta
					byte byteBriscola = (byte) (app & 0x01);	//and binario con 00000001 per ricavare il bit della briscola (ultimo bit)
					boolean briscola = (byteBriscola == 0x0) ? false : true;
					app = frame;
					app = (byte) (app >>> 1);					//shift a dx di un bit
					int byteToIntSeme = (int) (app & 0x03);		//and binario con 00000011 per ricavare il seme della carta (bit 5 e 6)
					Seme seme = Seme.values()[byteToIntSeme];
					app = frame;
					app = (byte) (app >>> 3);					//shift a dx di 3 bit (tolgo i 3 già analizzati)
					int valoreCarta = (int) (app & 0x0F);		//and binario con 00001111 per ricavare il numero della carta
					try{
						c = new Carta(valoreCarta, seme);
						c.setBriscola(briscola);
						System.out.println("Ricevuto: " + " [" + Integer.toBinaryString(frame).substring(24)+ "] "+ c.toString());
					} catch (IllegalArgumentException e){ 
						if(this.listener!=null) listener.onReceiveSincronizeSignal();
					}

				} else if(typeFrame == 0x0) {				//verifico che il frame ricevuto sia un token
					app = (byte) (app >>> 4);					//shift a dx di 4 bit
					byte turno = (byte) (app & 0x07);			//and binario con 00000111 per ricavare i bit del turno
					if(turno == 0x07 || turno == 0x00) {
						boolean turno_player = (turno == 0x07) ? true : false;
						this.gameTracker.setTurnoPlayer(turno_player);
						app = frame;
						byte presa = (byte) (app & 0x0F);			//and binario con 00001111 per ricavare i bit della presa
						if(presa == 0x0F) { this.gameTracker.setPresaValutata(true); this.gameTracker.setPrendePlayer(false); 	}
						else if(presa == 0x00) { this.gameTracker.setPresaValutata(true); this.gameTracker.setPrendePlayer(true); 	}
						else if(presa == 0x05) { this.gameTracker.setPresaValutata(false); }
						System.out.println("Ricevuto: TOKEN" + " [" + Integer.toBinaryString(frame)+ "]");
					}
				}
			}
			if(this.listener!=null) listener.onReceiveCarta(c);
		}
	}

	public byte fromCartaToByte (Carta c) {
		byte byteCarta = 0x1;		//frame di tipo carta, primo bit = 1
		byteCarta = (byte) (byteCarta << 4 | BigInteger.valueOf(c.getValore()).toByteArray()[0]);		//shift a sx di 4 bit e or binario con la conversione da int a bit del numero della carta
		byteCarta = (byte) (byteCarta << 2 | ((byte) c.getSeme().ordinal()));							//shift a sx di 2 bit e or binario con il seme in bit
		byte briscola = c.isBriscola() ? (byte) 0x1 : (byte) 0x0;
		byteCarta = (byte) (byteCarta << 1 | briscola);													//shift a sx di 1 bit e or binario con il bit della briscola
		return byteCarta;
	}
}
