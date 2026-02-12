import { BrowserRouter as Router } from 'react-router-dom';
import { AuthProvider } from './app/providers/AuthProvider';
import { BranchProvider } from './app/providers/BranchProvider';
import { PermissionProvider } from './app/providers/PermissionProvider';
import { NotificationProvider } from './app/providers/NotificationProvider';
import AppRoutes from './app/routes';
import './App.css';

import { ActivityProvider } from './app/providers/ActivityProvider';

import { InventoryProvider } from './app/providers/InventoryProvider';

function App() {
  return (
    <AuthProvider>
      <BranchProvider>
        <InventoryProvider>
          <PermissionProvider>
            <NotificationProvider>
              <ActivityProvider>
                <Router>
                  <AppRoutes />
                </Router>
              </ActivityProvider>
            </NotificationProvider>
          </PermissionProvider>
        </InventoryProvider>
      </BranchProvider>
    </AuthProvider>
  );
}

export default App;

