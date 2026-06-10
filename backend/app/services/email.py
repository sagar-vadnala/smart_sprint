"""
Email sending — used for organization invitations.

Graceful degradation by design: if SMTP isn't configured (no SMTP_HOST), we DON'T
send anything and return False. Callers then surface the accept link directly so
the invite flow still works end-to-end without an email provider. Configure the
SMTP_* env vars to start delivering real emails.
"""

import logging
import smtplib
from email.message import EmailMessage

from app.core.config import settings

logger = logging.getLogger("smartsprint")


def send_email(to: str, subject: str, html_body: str, text_body: str = "") -> bool:
    """Send an HTML email. Returns True if it was handed to the SMTP server,
    False if email is disabled or sending failed (never raises)."""
    if not settings.email_enabled:
        logger.info("Email disabled (SMTP not configured); skipping send to %s", to)
        return False

    msg = EmailMessage()
    msg["Subject"] = subject
    msg["From"] = settings.email_from_address
    msg["To"] = to
    msg.set_content(text_body or _strip_html(html_body))
    msg.add_alternative(html_body, subtype="html")

    try:
        if settings.smtp_use_tls:
            with smtplib.SMTP(settings.smtp_host, settings.smtp_port, timeout=15) as s:
                s.starttls()
                if settings.smtp_user:
                    s.login(settings.smtp_user, settings.smtp_password)
                s.send_message(msg)
        else:
            with smtplib.SMTP_SSL(settings.smtp_host, settings.smtp_port, timeout=15) as s:
                if settings.smtp_user:
                    s.login(settings.smtp_user, settings.smtp_password)
                s.send_message(msg)
        logger.info("Invite email sent to %s", to)
        return True
    except Exception:
        # Don't fail the request just because email delivery hiccuped — the
        # invite row still exists and the link is returned to the caller.
        logger.exception("Failed to send email to %s", to)
        return False


def _strip_html(html: str) -> str:
    import re

    text = re.sub(r"<[^>]+>", "", html)
    return re.sub(r"\n\s*\n+", "\n\n", text).strip()


def invite_email_html(*, org_name: str, inviter_name: str, accept_url: str) -> str:
    """The invitation email body."""
    return f"""\
<div style="font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;
            max-width:480px;margin:0 auto;padding:24px;color:#1a1a2e">
  <h2 style="font-size:20px;margin:0 0 8px">You're invited to join {org_name}</h2>
  <p style="font-size:14px;line-height:1.6;color:#555">
    {inviter_name} has invited you to collaborate in
    <strong>{org_name}</strong> on SmartSprint.
  </p>
  <a href="{accept_url}"
     style="display:inline-block;margin:16px 0;padding:12px 22px;background:#6C47FF;
            color:#fff;text-decoration:none;border-radius:10px;font-weight:600;
            font-size:14px">Accept invitation</a>
  <p style="font-size:12px;line-height:1.6;color:#888">
    Or paste this link into your browser:<br>
    <a href="{accept_url}" style="color:#6C47FF;word-break:break-all">{accept_url}</a>
  </p>
  <p style="font-size:12px;color:#aaa;margin-top:24px">
    If you didn't expect this invitation, you can safely ignore this email.
  </p>
</div>"""
