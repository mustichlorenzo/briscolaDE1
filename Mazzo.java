package application;

import java.io.File;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Random;

import javafx.scene.image.Image;

public class Mazzo {
	public static final int MAX_MAZZO = 40;
	public static final int N_SCAMBI = 1000;
	private int cartaCorrente = 7;
	private ArrayList<Carta> mazzo;
	private HashMap<String, Image> toImage;
	public Mazzo() {
		this.toImage = new HashMap<String, Image>();
		this.mazzo = creaMazzo();
	}

	private ArrayList<Carta> creaMazzo() {
		ArrayList<Carta> mazzo = new ArrayList<Carta>(40);
		Random gen = new Random();
		Carta c;
		for (int i=0; i<MAX_MAZZO; i++) {
			c=creaCarta(i);
			mazzo.add(c);
			addImage(c);
		}
		for(int i=0; i<N_SCAMBI; i++) {
			int c1 = gen.nextInt(MAX_MAZZO);
			int c2;
			do {
				c2 = gen.nextInt(MAX_MAZZO);
			} while (c2==c1);
			Carta car1 = mazzo.get(c1);
			Carta car2 = mazzo.get(c2);
			mazzo.set(c2, car1);
			mazzo.set(c1, car2);
		}
		return mazzo;
	}

	private void addImage(Carta c) {
		String startPath = "BriscolaFPGA/carte/napoletane/";
		String completePath = startPath + c.toString() + ".png";
		this.toImage.put(c.toString(), new Image(new File(completePath).toURI().toString()));
	}

	private Carta creaCarta(int i) {
		if(i<10) {
			return new Carta((i%10)+1, Seme.DENARI);
		}
		if(i>=10 && i<20) {
			return new Carta((i%10)+1, Seme.BASTONI);
		}
		if(i>=20 && i<30) {
			return new Carta((i%10)+1, Seme.COPPE);
		}
		if(i>=30 && i<40) {
			return new Carta((i%10)+1, Seme.SPADE);
		}
		return null;
	}
	
	public Carta getBriscola() {
		return mazzo.get(0);
	}
	
	public Image getImageFromCarta(Carta c) {
		return this.toImage.get(c.toString());
	}
	
	public ArrayList<Carta> getManoPlayer(boolean cominciaPlayer){
		if(cominciaPlayer) {
			return new ArrayList<Carta>(this.mazzo.subList(1, 4));
		}
		else return new ArrayList<Carta>(this.mazzo.subList(4, 7));
	}
	
	public ArrayList<Carta> getManoCPU(boolean cominciaPlayer){
		if(!cominciaPlayer) {
			return new ArrayList<Carta>(this.mazzo.subList(1, 4));
		}
		else return new ArrayList<Carta>(this.mazzo.subList(4, 7));
	}
	
	public void setBriscole(Carta briscola) {
		for(int i=0; i<MAX_MAZZO; i++) {
			if(briscola.getSeme() == mazzo.get(i).getSeme()) {
				mazzo.get(i).setBriscola(true);
			}
		}
	}

	public Carta getNextCard() {
		this.cartaCorrente++;
		return this.mazzo.get(cartaCorrente-1);
	}
	
	public boolean manoCPUContains(boolean giocaPlayer, Carta c) {
		for(Carta e : this.getManoCPU(giocaPlayer)) {
			if(e.equals(c)) return true;
		}
		return false;
	}
}
