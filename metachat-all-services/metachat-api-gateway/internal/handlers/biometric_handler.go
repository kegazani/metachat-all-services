package handlers

import (
	"bytes"
	"io"
	"net/http"
	"net/http/httputil"
	"net/url"
	"strings"
	"time"

	"github.com/gorilla/mux"
	"github.com/gorilla/websocket"
	"github.com/sirupsen/logrus"
)

type BiometricHandler struct {
	biometricServiceURL string
	httpClient          *http.Client
	logger              *logrus.Logger
	upgrader            websocket.Upgrader
}

func NewBiometricHandler(biometricServiceURL string, logger *logrus.Logger) *BiometricHandler {
	return &BiometricHandler{
		biometricServiceURL: biometricServiceURL,
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
		logger: logger,
		upgrader: websocket.Upgrader{
			ReadBufferSize:  1024,
			WriteBufferSize: 1024,
			CheckOrigin: func(r *http.Request) bool {
				return true
			},
		},
	}
}

func (h *BiometricHandler) RegisterRoutes(router *mux.Router) {
	router.HandleFunc("/biometric/watch/data", h.ReceiveWatchData).Methods("POST", "OPTIONS")
	router.HandleFunc("/biometric/profile/{user_id}", h.GetUserBiometricProfile).Methods("GET", "OPTIONS")
	router.HandleFunc("/biometric/summary/{user_id}", h.GetUserSummaries).Methods("GET", "OPTIONS")
	router.HandleFunc("/biometric/summary/{user_id}/today", h.GetTodaySummary).Methods("GET", "OPTIONS")
	router.HandleFunc("/biometric/data", h.ReceiveBiometricData).Methods("POST", "OPTIONS")
	router.HandleFunc("/biometric/data/{user_id}", h.GetBiometricData).Methods("GET", "OPTIONS")
	router.HandleFunc("/biometric/ws/{user_id}", h.WebSocketProxy).Methods("GET")
	
	router.HandleFunc("/biometric/emotional-state/{user_id}/current", h.GetCurrentEmotionalState).Methods("GET", "OPTIONS")
	router.HandleFunc("/biometric/emotional-state/{user_id}/day/{date}", h.GetDayEmotionalSummary).Methods("GET", "OPTIONS")
	router.HandleFunc("/biometric/insights/{user_id}/day/{date}", h.GetDayInsights).Methods("GET", "OPTIONS")
	router.HandleFunc("/biometric/spikes/{user_id}", h.GetEmotionalSpikes).Methods("GET", "OPTIONS")
}

func (h *BiometricHandler) proxyRequest(w http.ResponseWriter, r *http.Request, path string) {
	targetURL, err := url.Parse(h.biometricServiceURL)
	if err != nil {
		h.logger.WithError(err).Error("Failed to parse biometric service URL")
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	proxy := httputil.NewSingleHostReverseProxy(targetURL)

	proxy.Director = func(req *http.Request) {
		req.URL.Scheme = targetURL.Scheme
		req.URL.Host = targetURL.Host
		req.URL.Path = path
		req.URL.RawQuery = r.URL.RawQuery
		req.Host = targetURL.Host

		if correlationID := r.Header.Get("X-Correlation-ID"); correlationID != "" {
			req.Header.Set("X-Correlation-ID", correlationID)
		}
		if authHeader := r.Header.Get("Authorization"); authHeader != "" {
			req.Header.Set("Authorization", authHeader)
		}
		req.Header.Set("Content-Type", r.Header.Get("Content-Type"))
	}

	proxy.ErrorHandler = func(w http.ResponseWriter, r *http.Request, err error) {
		h.logger.WithError(err).Error("Proxy error")
		http.Error(w, "Biometric service unavailable", http.StatusServiceUnavailable)
	}

	h.logger.WithFields(logrus.Fields{
		"method": r.Method,
		"path":   path,
		"target": targetURL.String(),
	}).Debug("Proxying request to biometric service")

	proxy.ServeHTTP(w, r)
}

func (h *BiometricHandler) ReceiveWatchData(w http.ResponseWriter, r *http.Request) {
	if r.Method == "OPTIONS" {
		w.WriteHeader(http.StatusOK)
		return
	}
	h.proxyRequest(w, r, "/biometric/watch/data")
}

func (h *BiometricHandler) GetUserBiometricProfile(w http.ResponseWriter, r *http.Request) {
	if r.Method == "OPTIONS" {
		w.WriteHeader(http.StatusOK)
		return
	}
	vars := mux.Vars(r)
	userID := vars["user_id"]
	h.proxyRequest(w, r, "/biometric/profile/"+userID)
}

func (h *BiometricHandler) GetUserSummaries(w http.ResponseWriter, r *http.Request) {
	if r.Method == "OPTIONS" {
		w.WriteHeader(http.StatusOK)
		return
	}
	vars := mux.Vars(r)
	userID := vars["user_id"]
	h.proxyRequest(w, r, "/biometric/summary/"+userID)
}

func (h *BiometricHandler) GetTodaySummary(w http.ResponseWriter, r *http.Request) {
	if r.Method == "OPTIONS" {
		w.WriteHeader(http.StatusOK)
		return
	}
	vars := mux.Vars(r)
	userID := vars["user_id"]
	h.proxyRequest(w, r, "/biometric/summary/"+userID+"/today")
}

func (h *BiometricHandler) ReceiveBiometricData(w http.ResponseWriter, r *http.Request) {
	if r.Method == "OPTIONS" {
		w.WriteHeader(http.StatusOK)
		return
	}
	h.proxyRequest(w, r, "/biometric/data")
}

func (h *BiometricHandler) GetBiometricData(w http.ResponseWriter, r *http.Request) {
	if r.Method == "OPTIONS" {
		w.WriteHeader(http.StatusOK)
		return
	}
	vars := mux.Vars(r)
	userID := vars["user_id"]
	h.proxyRequest(w, r, "/biometric/data/"+userID)
}

func (h *BiometricHandler) GetCurrentEmotionalState(w http.ResponseWriter, r *http.Request) {
	if r.Method == "OPTIONS" {
		w.WriteHeader(http.StatusOK)
		return
	}
	vars := mux.Vars(r)
	userID := vars["user_id"]
	h.proxyRequest(w, r, "/biometric/emotional-state/"+userID+"/current")
}

func (h *BiometricHandler) GetDayEmotionalSummary(w http.ResponseWriter, r *http.Request) {
	if r.Method == "OPTIONS" {
		w.WriteHeader(http.StatusOK)
		return
	}
	vars := mux.Vars(r)
	userID := vars["user_id"]
	date := vars["date"]
	h.proxyRequest(w, r, "/biometric/emotional-state/"+userID+"/day/"+date)
}

func (h *BiometricHandler) GetDayInsights(w http.ResponseWriter, r *http.Request) {
	if r.Method == "OPTIONS" {
		w.WriteHeader(http.StatusOK)
		return
	}
	vars := mux.Vars(r)
	userID := vars["user_id"]
	date := vars["date"]
	h.proxyRequest(w, r, "/biometric/insights/"+userID+"/day/"+date)
}

func (h *BiometricHandler) GetEmotionalSpikes(w http.ResponseWriter, r *http.Request) {
	if r.Method == "OPTIONS" {
		w.WriteHeader(http.StatusOK)
		return
	}
	vars := mux.Vars(r)
	userID := vars["user_id"]
	h.proxyRequest(w, r, "/biometric/spikes/"+userID)
}

func (h *BiometricHandler) WebSocketProxy(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	userID := vars["user_id"]

	wsURL := strings.Replace(h.biometricServiceURL, "http://", "ws://", 1)
	wsURL = strings.Replace(wsURL, "https://", "wss://", 1)
	wsURL = wsURL + "/biometric/ws/" + userID

	h.logger.WithFields(logrus.Fields{
		"user_id":    userID,
		"target_url": wsURL,
	}).Info("Proxying WebSocket connection")

	clientConn, err := h.upgrader.Upgrade(w, r, nil)
	if err != nil {
		h.logger.WithError(err).Error("Failed to upgrade WebSocket connection")
		return
	}
	defer clientConn.Close()

	dialer := websocket.Dialer{
		HandshakeTimeout: 10 * time.Second,
	}

	serverConn, _, err := dialer.Dial(wsURL, nil)
	if err != nil {
		h.logger.WithError(err).Error("Failed to connect to biometric service WebSocket")
		clientConn.WriteMessage(websocket.CloseMessage,
			websocket.FormatCloseMessage(websocket.CloseInternalServerErr, "Failed to connect to biometric service"))
		return
	}
	defer serverConn.Close()

	done := make(chan struct{})

	go func() {
		defer close(done)
		for {
			messageType, message, err := serverConn.ReadMessage()
			if err != nil {
				if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseNormalClosure) {
					h.logger.WithError(err).Error("WebSocket read error from server")
				}
				return
			}
			if err := clientConn.WriteMessage(messageType, message); err != nil {
				h.logger.WithError(err).Error("WebSocket write error to client")
				return
			}
		}
	}()

	go func() {
		for {
			messageType, message, err := clientConn.ReadMessage()
			if err != nil {
				if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseNormalClosure) {
					h.logger.WithError(err).Error("WebSocket read error from client")
				}
				serverConn.WriteMessage(websocket.CloseMessage,
					websocket.FormatCloseMessage(websocket.CloseNormalClosure, ""))
				return
			}
			if err := serverConn.WriteMessage(messageType, message); err != nil {
				h.logger.WithError(err).Error("WebSocket write error to server")
				return
			}
		}
	}()

	<-done
}

func (h *BiometricHandler) makeRequest(method, path string, body []byte, headers map[string]string) (*http.Response, error) {
	url := h.biometricServiceURL + path

	var bodyReader io.Reader
	if body != nil {
		bodyReader = bytes.NewReader(body)
	}

	req, err := http.NewRequest(method, url, bodyReader)
	if err != nil {
		return nil, err
	}

	req.Header.Set("Content-Type", "application/json")
	for key, value := range headers {
		req.Header.Set(key, value)
	}

	return h.httpClient.Do(req)
}

