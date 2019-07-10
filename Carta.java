package application;

public class Carta {
	private int valore;
	private Seme seme;
	private boolean briscola;
	
	public Carta() {
		this.valore=0;
		this.seme=null;
	}
	public Carta(int valore, Seme seme) {
		if(valore < 1 || valore > 10) {
			throw new IllegalArgumentException();
		}
		this.valore = valore;
		this.seme = seme;
	}
	
	public int getValore() {
		return valore;
	}
	public Seme getSeme() {
		return seme;
	}
	public boolean isBriscola() {
		return briscola;
	}
	
	public void setBriscola(boolean briscola) {
		this.briscola = briscola;
	}
	
	public String toString() {
		if(this.valore == 0) return "Carta ERRATA";
		if(this.valore<10) return "0"+valore+"_"+seme.toString();
		else return valore+"_"+seme.toString();
	}
	
	public boolean equals(Carta c) {
		if(c==null) return false;
		if((c.briscola == this.briscola) && (c.seme==this.seme) && (c.valore==this.valore)) return true;
		return false;
	}
}
