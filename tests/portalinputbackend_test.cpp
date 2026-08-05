// SPDX-FileCopyrightText: 2026 AnicetusCer
// SPDX-License-Identifier: GPL-3.0-or-later

#include "portalinputbackend.h"

#include <QFile>
#include <QSettings>
#include <QTemporaryDir>
#include <QTest>

class PortalInputBackendTest final : public QObject
{
    Q_OBJECT

private slots:
    void forgetsSavedPermissionState()
    {
        QCoreApplication::setOrganizationName(QStringLiteral("ImboardTests"));
        QCoreApplication::setApplicationName(QStringLiteral("PortalInputBackend"));
        QSettings settings;
        settings.clear();
        settings.setValue(QStringLiteral("portal/setupComplete"), true);
        settings.setValue(QStringLiteral("portal/restoreToken"), QStringLiteral("secret-token"));

        PortalInputBackend backend;
        QVERIFY(backend.setupComplete());
        QVERIFY(backend.forgetPermission());
        QVERIFY(!backend.setupComplete());
        QVERIFY(!settings.contains(QStringLiteral("portal/setupComplete")));
        QVERIFY(!settings.contains(QStringLiteral("portal/restoreToken")));
        QCOMPARE(backend.status(), QStringLiteral("Access removed"));
    }

    void rejectsIncompleteSavedPermissionState()
    {
        QSettings settings;
        settings.clear();
        settings.setValue(QStringLiteral("portal/setupComplete"), true);
        settings.remove(QStringLiteral("portal/restoreToken"));

        const PortalInputBackend backend;
        QVERIFY(!backend.setupComplete());
    }

    void protectsSavedPermissionState()
    {
        QSettings settings;
        settings.clear();
        settings.setValue(QStringLiteral("portal/setupComplete"), true);
        settings.setValue(QStringLiteral("portal/restoreToken"), QStringLiteral("secret-token"));
        settings.sync();
        QCOMPARE(settings.status(), QSettings::NoError);
        const QString settingsPath = settings.fileName();
        QVERIFY(QFile::setPermissions(
            settingsPath,
            QFileDevice::ReadOwner | QFileDevice::WriteOwner | QFileDevice::ReadGroup
                | QFileDevice::ReadOther));

        const PortalInputBackend backend;
        QVERIFY(backend.setupComplete());
        const QFileDevice::Permissions permissions = QFile::permissions(settingsPath);
        QVERIFY(permissions.testFlag(QFileDevice::ReadOwner));
        QVERIFY(permissions.testFlag(QFileDevice::WriteOwner));
        QVERIFY(!(permissions
                  & (QFileDevice::ExeOwner | QFileDevice::ReadGroup
                     | QFileDevice::WriteGroup | QFileDevice::ExeGroup
                     | QFileDevice::ReadOther | QFileDevice::WriteOther
                     | QFileDevice::ExeOther)));
    }

    void waitsForUnavailablePortalDuringRestore()
    {
        QSettings settings;
        settings.clear();
        settings.setValue(QStringLiteral("portal/setupComplete"), true);
        settings.setValue(QStringLiteral("portal/restoreToken"), QStringLiteral("secret-token"));

        PortalInputBackend backend;
        backend.restoreIfConfigured();
        QVERIFY(!backend.ready());
        QCOMPARE(backend.status(), QStringLiteral("Waiting for desktop portal"));
    }

    void recoversConfiguredSessionClosure()
    {
        QSettings settings;
        settings.clear();
        settings.setValue(QStringLiteral("portal/setupComplete"), true);
        settings.setValue(QStringLiteral("portal/restoreToken"), QStringLiteral("secret-token"));

        PortalInputBackend backend;
        backend.restoreIfConfigured();
        QVERIFY(QMetaObject::invokeMethod(&backend, "handleSessionClosed",
                                         Qt::DirectConnection));

        QVERIFY(!backend.ready());
        QVERIFY(backend.setupComplete());
        QCOMPARE(backend.status(), QStringLiteral("Waiting for desktop portal"));
    }

    void retriesStalledNonInteractiveRestore()
    {
        QSettings settings;
        settings.clear();
        settings.setValue(QStringLiteral("portal/setupComplete"), true);
        settings.setValue(QStringLiteral("portal/restoreToken"), QStringLiteral("secret-token"));

        PortalInputBackend backend;
        backend.m_connectionWanted = true;
        backend.m_stage = PortalInputBackend::Stage::Selecting;
        backend.handleRequestTimeout();

        QVERIFY(!backend.ready());
        QVERIFY(backend.m_connectionWanted);
        QCOMPARE(backend.m_stage, PortalInputBackend::Stage::Waiting);
        QCOMPARE(backend.m_requestTimeoutRetries, 1);
        QCOMPARE(backend.status(), QStringLiteral("Waiting for desktop portal"));
    }

    void doesNotRetryStalledPermissionDecision()
    {
        QSettings settings;
        settings.clear();
        settings.setValue(QStringLiteral("portal/setupComplete"), true);
        settings.setValue(QStringLiteral("portal/restoreToken"), QStringLiteral("secret-token"));

        PortalInputBackend backend;
        backend.m_connectionWanted = true;
        backend.m_stage = PortalInputBackend::Stage::Starting;
        backend.handleRequestTimeout();

        QVERIFY(!backend.ready());
        QVERIFY(!backend.m_connectionWanted);
        QCOMPARE(backend.m_stage, PortalInputBackend::Stage::Error);
        QCOMPARE(backend.status(),
                 QStringLiteral("The keyboard permission request timed out"));
    }

    void reportsPermissionRemovalFailure()
    {
        QTemporaryDir directory;
        QVERIFY(directory.isValid());
        QSettings::setDefaultFormat(QSettings::IniFormat);
        QSettings::setPath(QSettings::IniFormat, QSettings::UserScope, directory.path());

        QSettings settings;
        settings.setValue(QStringLiteral("portal/setupComplete"), true);
        settings.setValue(QStringLiteral("portal/restoreToken"), QStringLiteral("secret-token"));
        settings.sync();
        QCOMPARE(settings.status(), QSettings::NoError);
        const QString settingsPath = settings.fileName();
        QVERIFY(QFile::setPermissions(settingsPath, QFileDevice::ReadOwner));
        QVERIFY(QFile::setPermissions(directory.path(),
                                      QFileDevice::ReadOwner | QFileDevice::ExeOwner));

        PortalInputBackend backend;
        QVERIFY(!backend.forgetPermission());
        QCOMPARE(backend.status(),
                 QStringLiteral("Could not delete the saved keyboard permission"));

        QVERIFY(QFile::setPermissions(directory.path(),
                                      QFileDevice::ReadOwner | QFileDevice::WriteOwner
                                          | QFileDevice::ExeOwner));
        QVERIFY(QFile::setPermissions(settingsPath,
                                      QFileDevice::ReadOwner | QFileDevice::WriteOwner));
    }
};

QTEST_GUILESS_MAIN(PortalInputBackendTest)

#include "portalinputbackend_test.moc"
