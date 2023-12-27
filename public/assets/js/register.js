var passwordField = document.getElementById('password');
var confirmField = document.getElementById('confirm_password');
var togglePassword = document.getElementById('togglePassword');
var toggleConfirmPassword = document.getElementById('toggleConfirmPassword');

togglePassword.onclick = function () {
  togglePasswordField();
};

toggleConfirmPassword.onclick = function () {
  togglePasswordField(confirmField, toggleConfirmPassword);
};

function togglePasswordField(field = passwordField, toggleButton = togglePassword) {
  var type = field.getAttribute('type') === 'password' ? 'text' : 'password';
  field.setAttribute('type', type);
  toggleButton.className = type === 'password' ? 'fa-solid fa-eye' : 'fa-solid fa-eye-slash';
}

function validatePassword() {
  var password = passwordField.value;
  var confirmPassword = confirmField.value;
  var warningIcon = document.getElementById('password_match_warning');
  var warningMessage = document.getElementById('password_match_message');

  if (password.length < 6) {
    warningIcon.style.display = 'inline';
    warningMessage.style.display = 'inline';
    warningMessage.innerText = 'Password must be at least 6 characters long.';
    return false;
  } else if (password !== confirmPassword) {
    warningIcon.style.display = 'inline';
    warningMessage.style.display = 'inline';
    warningMessage.innerText = 'Confirm passwords do not match!';
    return false;
  } else {
    warningIcon.style.display = 'none';
    warningMessage.style.display = 'none';
    return true;
  }
}
