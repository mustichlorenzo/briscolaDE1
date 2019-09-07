package application;

public interface ReceiveCartaEventListener {
	void onReceiveCarta(Carta c);
	void onReceiveSincronizeSignal();
}
