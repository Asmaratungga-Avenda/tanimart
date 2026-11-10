<?php

namespace App\Filament\Resources\Banners\Schemas;

use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Schemas\Schema;

class BannerForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                FileUpload::make('gambar')
                    ->label('Gambar Banner Promo')
                    ->image()
                    ->disk('public')
                    ->directory('banners')
                    ->visibility('public')
                    ->imagePreviewHeight(200)
                    ->imageResizeTargetWidth(1600)
                    ->imageResizeTargetHeight(900)
                    ->imageResizeMode('contain')
                    ->maxSize(10240)
                    ->required()
                    ->columnSpanFull(),
                TextInput::make('judul')
                    ->label('Judul Banner')
                    ->required()
                    ->maxLength(255),
                TextInput::make('link')
                    ->label('Tautan / Deep Link (Opsional)')
                    ->nullable()
                    ->maxLength(255),
                TextInput::make('urutan')
                    ->label('Urutan Tampilan')
                    ->numeric()
                    ->default(0)
                    ->required(),
                Toggle::make('aktif')
                    ->label('Status Aktif')
                    ->default(true),
            ]);
    }
}
