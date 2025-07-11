-- DPDP Act 2023 Consent Management Database Schema
-- This schema implements the database structure required for
-- Digital Personal Data Protection Act 2023 compliance

-- Enable RLS (Row Level Security) for all tables
-- This ensures users can only access their own data

-- 1. User Consents Table
-- Stores individual consent records for each user and consent type
CREATE TABLE IF NOT EXISTS public.user_consents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    type TEXT NOT NULL CHECK (type IN (
        'essential', 
        'location', 
        'marketing', 
        'analytics', 
        'personalization', 
        'thirdPartySharing', 
        'cookies',
        'unknown'
    )),
    is_granted BOOLEAN NOT NULL DEFAULT false,
    granted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    revoked_at TIMESTAMPTZ NULL,
    revoked_reason TEXT NULL,
    source TEXT NOT NULL CHECK (source IN (
        'onboarding',
        'settings',
        'featurePrompt',
        'registration',
        'legalScreen',
        'system',
        'unknown'
    )),
    version TEXT NOT NULL DEFAULT '1.0.0',
    metadata JSONB NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_consents_user_id ON public.user_consents(user_id);
CREATE INDEX IF NOT EXISTS idx_user_consents_type ON public.user_consents(type);
CREATE INDEX IF NOT EXISTS idx_user_consents_granted_at ON public.user_consents(granted_at);
CREATE INDEX IF NOT EXISTS idx_user_consents_user_type ON public.user_consents(user_id, type);

-- Enable RLS
ALTER TABLE public.user_consents ENABLE ROW LEVEL SECURITY;

-- RLS Policies for user_consents
CREATE POLICY "Users can view their own consents" ON public.user_consents
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own consents" ON public.user_consents
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own consents" ON public.user_consents
    FOR UPDATE USING (auth.uid() = user_id);

-- 2. Consent Audit Log Table
-- Maintains audit trail for all consent-related actions
CREATE TABLE IF NOT EXISTS public.consent_audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    action TEXT NOT NULL CHECK (action IN (
        'grant',
        'revoke',
        'update',
        'delete_all',
        'export',
        'view'
    )),
    consent_type TEXT NULL,
    consent_id UUID NULL,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    metadata JSONB NULL,
    ip_address TEXT NULL,
    user_agent TEXT NULL
);

-- Add indexes for audit log
CREATE INDEX IF NOT EXISTS idx_consent_audit_user_id ON public.consent_audit_log(user_id);
CREATE INDEX IF NOT EXISTS idx_consent_audit_timestamp ON public.consent_audit_log(timestamp);
CREATE INDEX IF NOT EXISTS idx_consent_audit_action ON public.consent_audit_log(action);

-- Enable RLS for audit log
ALTER TABLE public.consent_audit_log ENABLE ROW LEVEL SECURITY;

-- RLS Policies for consent_audit_log
CREATE POLICY "Users can view their own audit logs" ON public.consent_audit_log
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "System can insert audit logs" ON public.consent_audit_log
    FOR INSERT WITH CHECK (true); -- Allow system to log all actions

-- 3. Data Correction Requests Table
-- Handles user requests for data correction (DPDP Right to Correction)
CREATE TABLE IF NOT EXISTS public.data_correction_requests (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL,
    corrections JSONB NOT NULL,
    reason TEXT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN (
        'pending',
        'processing',
        'completed',
        'rejected',
        'cancelled'
    )),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    estimated_completion TIMESTAMPTZ NULL,
    completed_at TIMESTAMPTZ NULL,
    processing_notes TEXT NULL,
    metadata JSONB NULL
);

-- Add indexes for correction requests
CREATE INDEX IF NOT EXISTS idx_correction_requests_user_id ON public.data_correction_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_correction_requests_status ON public.data_correction_requests(status);
CREATE INDEX IF NOT EXISTS idx_correction_requests_created_at ON public.data_correction_requests(created_at);

-- Enable RLS
ALTER TABLE public.data_correction_requests ENABLE ROW LEVEL SECURITY;

-- RLS Policies for data_correction_requests
CREATE POLICY "Users can view their own correction requests" ON public.data_correction_requests
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own correction requests" ON public.data_correction_requests
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 4. Data Deletion Requests Table
-- Handles user requests for data deletion (DPDP Right to Erasure)
CREATE TABLE IF NOT EXISTS public.data_deletion_requests (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL,
    reason TEXT NOT NULL,
    scope TEXT NOT NULL CHECK (scope IN ('profile', 'orders', 'complete')),
    status TEXT NOT NULL DEFAULT 'pending_approval' CHECK (status IN (
        'pending_approval',
        'approved',
        'processing',
        'completed',
        'rejected',
        'cancelled'
    )),
    requires_approval BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    estimated_completion TIMESTAMPTZ NULL,
    completed_at TIMESTAMPTZ NULL,
    processing_notes TEXT NULL,
    metadata JSONB NULL
);

-- Add indexes for deletion requests
CREATE INDEX IF NOT EXISTS idx_deletion_requests_user_id ON public.data_deletion_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_deletion_requests_status ON public.data_deletion_requests(status);
CREATE INDEX IF NOT EXISTS idx_deletion_requests_created_at ON public.data_deletion_requests(created_at);

-- Enable RLS
ALTER TABLE public.data_deletion_requests ENABLE ROW LEVEL SECURITY;

-- RLS Policies for data_deletion_requests
CREATE POLICY "Users can view their own deletion requests" ON public.data_deletion_requests
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own deletion requests" ON public.data_deletion_requests
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 5. Data Rights Audit Log Table
-- Comprehensive audit trail for all data rights activities
CREATE TABLE IF NOT EXISTS public.data_rights_audit_log (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL,
    action TEXT NOT NULL CHECK (action IN (
        'export',
        'correction',
        'deletion',
        'portability'
    )),
    details JSONB NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ip_address TEXT NULL,
    user_agent TEXT NULL
);

-- Add indexes for data rights audit log
CREATE INDEX IF NOT EXISTS idx_data_rights_audit_user_id ON public.data_rights_audit_log(user_id);
CREATE INDEX IF NOT EXISTS idx_data_rights_audit_timestamp ON public.data_rights_audit_log(timestamp);
CREATE INDEX IF NOT EXISTS idx_data_rights_audit_action ON public.data_rights_audit_log(action);

-- Enable RLS
ALTER TABLE public.data_rights_audit_log ENABLE ROW LEVEL SECURITY;

-- RLS Policies for data_rights_audit_log
CREATE POLICY "Users can view their own data rights audit logs" ON public.data_rights_audit_log
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "System can insert data rights audit logs" ON public.data_rights_audit_log
    FOR INSERT WITH CHECK (true);

-- 6. Update Triggers
-- Automatically update the updated_at timestamp

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add trigger to user_consents table
DROP TRIGGER IF EXISTS update_user_consents_updated_at ON public.user_consents;
CREATE TRIGGER update_user_consents_updated_at
    BEFORE UPDATE ON public.user_consents
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 7. Views for Analytics and Reporting

-- Consent summary view for easy querying
CREATE OR REPLACE VIEW public.consent_summary AS
SELECT 
    user_id,
    COUNT(*) as total_consents,
    COUNT(CASE WHEN is_granted = true AND revoked_at IS NULL THEN 1 END) as active_consents,
    COUNT(CASE WHEN is_granted = false OR revoked_at IS NOT NULL THEN 1 END) as revoked_consents,
    MAX(granted_at) as last_consent_date,
    MAX(updated_at) as last_updated
FROM public.user_consents
GROUP BY user_id;

-- Data rights requests summary view
CREATE OR REPLACE VIEW public.data_rights_summary AS
SELECT 
    user_id,
    COUNT(*) as total_requests,
    COUNT(CASE WHEN status IN ('pending', 'pending_approval', 'processing') THEN 1 END) as pending_requests,
    COUNT(CASE WHEN status IN ('completed', 'approved') THEN 1 END) as completed_requests,
    COUNT(CASE WHEN status IN ('rejected', 'cancelled') THEN 1 END) as failed_requests,
    MAX(created_at) as last_request_date
FROM (
    SELECT user_id, status, created_at FROM public.data_correction_requests
    UNION ALL
    SELECT user_id, status, created_at FROM public.data_deletion_requests
) combined_requests
GROUP BY user_id;

-- Grant necessary permissions
-- Note: In production, you should create specific roles with limited permissions

-- Comments for documentation
COMMENT ON TABLE public.user_consents IS 'Stores user consent records for DPDP Act 2023 compliance';
COMMENT ON TABLE public.consent_audit_log IS 'Audit trail for all consent-related actions';
COMMENT ON TABLE public.data_correction_requests IS 'User requests for data correction (Right to Correction)';
COMMENT ON TABLE public.data_deletion_requests IS 'User requests for data deletion (Right to Erasure)';
COMMENT ON TABLE public.data_rights_audit_log IS 'Audit trail for data rights activities';

-- Success message
SELECT 'DPDP Act 2023 consent management schema created successfully!' as result;
