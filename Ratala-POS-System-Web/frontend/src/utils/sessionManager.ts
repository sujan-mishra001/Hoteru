/**
 * Session Manager - Handles session control, token expiration, and idle timeout
 */

interface SessionData {
    token: string;
    expiresAt: number;
    lastActivity: number;
    role: string;
    branchId?: number;
}

const SESSION_KEY = 'app_session';
const IDLE_TIMEOUT = 30 * 60 * 1000; // 30 minutes of inactivity
const TOKEN_REFRESH_THRESHOLD = 5 * 60 * 1000; // Refresh token 5 minutes before expiry

class SessionManager {
    private idleTimer: number | null = null;
    private expiryCheckTimer: number | null = null;
    private onSessionExpired: (() => void) | null = null;

    /**
     * Initialize session with token and metadata
     */
    setSession(token: string, expiresInMinutes: number = 30, role: string = '', branchId?: number): void {
        const now = Date.now();
        const sessionData: SessionData = {
            token,
            expiresAt: now + (expiresInMinutes * 60 * 1000),
            lastActivity: now,
            role,
            branchId
        };

        localStorage.setItem(SESSION_KEY, JSON.stringify(sessionData));
        localStorage.setItem('token', token); // Keep for backward compatibility

        this.startIdleTimer();
        this.startExpiryCheck();
    }

    /**
     * Get current session data
     */
    getSession(): SessionData | null {
        const sessionStr = localStorage.getItem(SESSION_KEY);
        if (!sessionStr) return null;

        try {
            const session: SessionData = JSON.parse(sessionStr);

            // Check if token is expired
            if (Date.now() > session.expiresAt) {
                this.clearSession();
                return null;
            }

            return session;
        } catch {
            this.clearSession();
            return null;
        }
    }

    /**
     * Get token from session
     */
    getToken(): string | null {
        const session = this.getSession();
        return session?.token || null;
    }

    /**
     * Update last activity timestamp
     */
    updateActivity(): void {
        const session = this.getSession();
        if (session) {
            session.lastActivity = Date.now();
            localStorage.setItem(SESSION_KEY, JSON.stringify(session));
            this.resetIdleTimer();
        }
    }

    /**
     * Check if session is valid
     */
    isSessionValid(): boolean {
        const session = this.getSession();
        if (!session) return false;

        const now = Date.now();

        // Check token expiration
        if (now > session.expiresAt) {
            return false;
        }

        // Check idle timeout
        if (now - session.lastActivity > IDLE_TIMEOUT) {
            return false;
        }

        return true;
    }

    /**
     * Check if token needs refresh
     */
    needsRefresh(): boolean {
        const session = this.getSession();
        if (!session) return false;

        const timeUntilExpiry = session.expiresAt - Date.now();
        return timeUntilExpiry < TOKEN_REFRESH_THRESHOLD && timeUntilExpiry > 0;
    }

    /**
     * Clear session and cleanup
     */
    clearSession(): void {
        localStorage.removeItem(SESSION_KEY);
        localStorage.removeItem('token');
        localStorage.removeItem('role');
        localStorage.removeItem('currentBranchId');
        this.stopTimers();
    }

    /**
     * Set callback for session expiration
     */
    onExpired(callback: () => void): void {
        this.onSessionExpired = callback;
    }

    /**
     * Start idle timeout timer
     */
    private startIdleTimer(): void {
        this.resetIdleTimer();

        // Track user activity
        const activityEvents = ['mousedown', 'keydown', 'scroll', 'touchstart', 'click'];
        activityEvents.forEach(event => {
            window.addEventListener(event, this.handleActivity);
        });
    }

    /**
     * Handle user activity
     */
    private handleActivity = (): void => {
        this.updateActivity();
    };

    /**
     * Reset idle timer
     */
    private resetIdleTimer(): void {
        if (this.idleTimer) {
            clearTimeout(this.idleTimer);
        }

        this.idleTimer = setTimeout(() => {
            console.log('Session expired due to inactivity');
            this.handleSessionExpired();
        }, IDLE_TIMEOUT);
    }

    /**
     * Start token expiry check
     */
    private startExpiryCheck(): void {
        if (this.expiryCheckTimer) {
            clearInterval(this.expiryCheckTimer);
        }

        // Check every minute
        this.expiryCheckTimer = setInterval(() => {
            if (!this.isSessionValid()) {
                console.log('Session expired');
                this.handleSessionExpired();
            }
        }, 60 * 1000);
    }

    /**
     * Handle session expiration
     */
    private handleSessionExpired(): void {
        this.clearSession();
        if (this.onSessionExpired) {
            this.onSessionExpired();
        }
    }

    /**
     * Stop all timers and cleanup
     */
    private stopTimers(): void {
        if (this.idleTimer) {
            clearTimeout(this.idleTimer);
            this.idleTimer = null;
        }

        if (this.expiryCheckTimer) {
            clearInterval(this.expiryCheckTimer);
            this.expiryCheckTimer = null;
        }

        // Remove activity listeners
        const activityEvents = ['mousedown', 'keydown', 'scroll', 'touchstart', 'click'];
        activityEvents.forEach(event => {
            window.removeEventListener(event, this.handleActivity);
        });
    }

    /**
     * Get time until session expires (in milliseconds)
     */
    getTimeUntilExpiry(): number {
        const session = this.getSession();
        if (!session) return 0;
        return Math.max(0, session.expiresAt - Date.now());
    }

    /**
     * Get time since last activity (in milliseconds)
     */
    getTimeSinceActivity(): number {
        const session = this.getSession();
        if (!session) return 0;
        return Date.now() - session.lastActivity;
    }
}

// Export singleton instance
export const sessionManager = new SessionManager();
export default sessionManager;
