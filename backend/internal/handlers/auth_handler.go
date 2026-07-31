package handlers

import (
	"net/http"

	"mediguide/internal/httpx"
	"mediguide/internal/middleware"
	"mediguide/internal/models"
	"mediguide/internal/security"
	"mediguide/internal/services"

	"github.com/gin-gonic/gin"
)

type AuthHandler struct{ Service services.AuthService }

// Register godoc
// @Summary Register a user
// @Description Create a new backend user account.
// @Tags auth
// @Accept json
// @Produce json
// @Param payload body handlers.RegisterRequest true "Registration payload"
// @Success 201 {object} handlers.UserEnvelope
// @Failure 400 {object} handlers.ErrorResponse
// @Router /api/v2/auth/register [post]
func (h AuthHandler) Register(c *gin.Context) {
	var req RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		httpx.Error(c, http.StatusBadRequest, err.Error())
		return
	}
	u, err := h.Service.Register(services.RegisterInput{
		Name:              req.Name,
		Email:             req.Email,
		Password:          req.Password,
		Phone:             req.Phone,
		AlternativePhone:  req.AlternativePhone,
		FacilityID:        req.FacilityID,
		Address:           req.Address,
		City:              req.City,
		Country:           req.Country,
		PostalCode:        req.PostalCode,
		LicenseNumber:     req.LicenseNumber,
		Organization:      req.Organization,
		Department:        req.Department,
		JobTitle:          req.JobTitle,
		PreferredLanguage: req.PreferredLanguage,
		Timezone:          req.Timezone,
		Notes:             req.Notes,
		Specialization:    models.StringList(req.Specialization),
		Avatar:            req.Avatar,
	})
	if err != nil {
		httpx.Error(c, http.StatusBadRequest, err.Error())
		return
	}
	httpx.Created(c, u)
}

// Login godoc
// @Summary Log in a user
// @Description Authenticate a user and return a JWT bearer token.
// @Tags auth
// @Accept json
// @Produce json
// @Param payload body handlers.LoginRequest true "Login payload"
// @Success 200 {object} handlers.LoginEnvelope
// @Failure 400 {object} handlers.ErrorResponse
// @Failure 401 {object} handlers.ErrorResponse
// @Router /api/v2/auth/login [post]
func (h AuthHandler) Login(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		httpx.Error(c, http.StatusBadRequest, err.Error())
		return
	}
	res, err := h.Service.Login(req.Email, req.Password, services.RequestMetadata{
		UserAgent: c.Request.UserAgent(),
		IPAddress: c.ClientIP(),
	})
	if err != nil {
		httpx.Error(c, http.StatusUnauthorized, err.Error())
		return
	}
	httpx.OK(c, res)
}

// Refresh godoc
// @Summary Refresh a user session
// @Description Exchange a refresh token for a new access token and rotated refresh token.
// @Tags auth
// @Accept json
// @Produce json
// @Param payload body handlers.RefreshRequest true "Refresh payload"
// @Success 200 {object} handlers.LoginEnvelope
// @Failure 400 {object} handlers.ErrorResponse
// @Failure 401 {object} handlers.ErrorResponse
// @Router /api/v2/auth/refresh [post]
func (h AuthHandler) Refresh(c *gin.Context) {
	var req RefreshRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		httpx.Error(c, http.StatusBadRequest, err.Error())
		return
	}
	res, err := h.Service.Refresh(req.RefreshToken, services.RequestMetadata{
		UserAgent: c.Request.UserAgent(),
		IPAddress: c.ClientIP(),
	})
	if err != nil {
		httpx.Error(c, http.StatusUnauthorized, err.Error())
		return
	}
	httpx.OK(c, res)
}

// Logout godoc
// @Summary Log out current session
// @Description Revoke the current authenticated session.
// @Tags auth
// @Produce json
// @Security BearerAuth
// @Success 200 {object} handlers.LogoutEnvelope
// @Failure 401 {object} handlers.ErrorResponse
// @Router /api/v2/auth/logout [post]
func (h AuthHandler) Logout(c *gin.Context) {
	claims := c.MustGet(middleware.ClaimsKey).(*security.Claims)
	if claims.SessionID == "" {
		httpx.Error(c, http.StatusUnauthorized, "invalid session")
		return
	}
	if err := h.Service.Logout(claims.SessionID); err != nil {
		httpx.Error(c, http.StatusUnauthorized, err.Error())
		return
	}
	httpx.OK(c, LogoutResult{LoggedOut: true})
}

// Me godoc
// @Summary Get current user
// @Description Return the currently authenticated user.
// @Tags auth
// @Produce json
// @Security BearerAuth
// @Success 200 {object} handlers.UserEnvelope
// @Failure 404 {object} handlers.ErrorResponse
// @Failure 401 {object} handlers.ErrorResponse
// @Router /api/v2/me [get]
func (h AuthHandler) Me(c *gin.Context) {
	claims := c.MustGet(middleware.ClaimsKey).(*security.Claims)
	u, err := h.Service.Me(claims.UserID)
	if err != nil {
		httpx.Error(c, http.StatusNotFound, "user not found")
		return
	}
	httpx.OK(c, u)
}

// ChangePassword godoc
// @Summary Change the current user's password
// @Tags auth
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param payload body handlers.PasswordChangeRequest true "Password change"
// @Success 200 {object} handlers.LogoutEnvelope
// @Failure 400 {object} handlers.ErrorResponse
// @Failure 401 {object} handlers.ErrorResponse
// @Router /api/v2/me/password [post]
func (h AuthHandler) ChangePassword(c *gin.Context) {
	var req PasswordChangeRequest
	if c.ShouldBindJSON(&req) != nil || req.NewPassword != req.NewPasswordConfirm {
		httpx.Error(c, http.StatusBadRequest, "invalid request body")
		return
	}
	claims := c.MustGet(middleware.ClaimsKey).(*security.Claims)
	if err := h.Service.ChangePassword(claims.UserID, claims.SessionID, req.CurrentPassword, req.NewPassword); err != nil {
		httpx.Error(c, http.StatusBadRequest, "password change failed")
		return
	}
	httpx.OK(c, LogoutResult{LoggedOut: false})
}

// RequestPasswordReset godoc
// @Summary Request a password reset
// @Tags auth
// @Accept json
// @Produce json
// @Param payload body handlers.PasswordResetRequest true "Reset request"
// @Success 200 {object} services.AccountActionResult
// @Router /api/v2/auth/password-reset/request [post]
func (h AuthHandler) RequestPasswordReset(c *gin.Context) {
	var req PasswordResetRequest
	if c.ShouldBindJSON(&req) != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid request body")
		return
	}
	result, err := h.Service.RequestPasswordReset(req.Email)
	if err != nil {
		httpx.Error(c, http.StatusInternalServerError, "password reset request failed")
		return
	}
	httpx.OK(c, result)
}

// ConfirmPasswordReset godoc
// @Summary Confirm a password reset
// @Tags auth
// @Accept json
// @Produce json
// @Param payload body handlers.PasswordResetConfirmRequest true "Reset confirmation"
// @Success 200 {object} handlers.LogoutResult
// @Failure 400 {object} handlers.ErrorResponse
// @Router /api/v2/auth/password-reset/confirm [post]
func (h AuthHandler) ConfirmPasswordReset(c *gin.Context) {
	var req PasswordResetConfirmRequest
	if c.ShouldBindJSON(&req) != nil || req.Password != req.PasswordConfirm {
		httpx.Error(c, http.StatusBadRequest, "invalid request body")
		return
	}
	if err := h.Service.ConfirmPasswordReset(req.Token, req.Password); err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid or expired reset token")
		return
	}
	httpx.OK(c, LogoutResult{LoggedOut: true})
}

// RequestEmailVerification godoc
// @Summary Request email verification
// @Description Accept an email-verification request without revealing whether the address exists.
// @Tags auth
// @Accept json
// @Produce json
// @Param payload body handlers.EmailVerificationRequest true "Verification request"
// @Success 200 {object} services.AccountActionResult
// @Failure 400 {object} handlers.ErrorResponse
// @Router /api/v2/auth/email-verification/request [post]
func (h AuthHandler) RequestEmailVerification(c *gin.Context) {
	var req EmailVerificationRequest
	if c.ShouldBindJSON(&req) != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid request body")
		return
	}
	result, err := h.Service.RequestEmailVerification(req.Email)
	if err != nil {
		httpx.Error(c, http.StatusInternalServerError, "email verification request failed")
		return
	}
	httpx.OK(c, result)
}

// ConfirmEmailVerification godoc
// @Summary Confirm email verification
// @Tags auth
// @Accept json
// @Produce json
// @Param payload body handlers.EmailVerificationConfirmRequest true "Verification confirmation"
// @Success 200 {object} handlers.VerificationResultEnvelope
// @Failure 400 {object} handlers.ErrorResponse
// @Router /api/v2/auth/email-verification/confirm [post]
func (h AuthHandler) ConfirmEmailVerification(c *gin.Context) {
	var req EmailVerificationConfirmRequest
	if c.ShouldBindJSON(&req) != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid request body")
		return
	}
	if err := h.Service.ConfirmEmailVerification(req.Token); err != nil {
		httpx.Error(c, http.StatusBadRequest, "invalid or expired verification token")
		return
	}
	httpx.OK(c, VerificationResult{Verified: true})
}
