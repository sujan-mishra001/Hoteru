import { BrowserRouter as Router } from 'react-router-dom';
import { AuthProvider } from './app/providers/AuthProvider';
import { BranchProvider } from './app/providers/BranchProvider';
import { PermissionProvider } from './app/providers/PermissionProvider';
import { NotificationProvider } from './app/providers/NotificationProvider';
import AppRoutes from './app/routes';
import './App.css';

import { ActivityProvider } from './app/providers/ActivityProvider';

function App() {
  return (
    <AuthProvider>
      <BranchProvider>
        <PermissionProvider>
          <NotificationProvider>
            <ActivityProvider>
              <Router>
                <AppRoutes />
              </Router>
            </ActivityProvider>
          </NotificationProvider>
        </PermissionProvider>
      </BranchProvider>
    </AuthProvider>
  );
}

export default App;
